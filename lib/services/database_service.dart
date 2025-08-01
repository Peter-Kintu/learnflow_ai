// learnflow_ai/flutter_app/lib/services/database_service.dart

import 'dart:async';
import 'dart:convert'; // For JSON encoding/decoding for complex types
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/models/student_progress.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // For web support

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._constructor();

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_database != null) {
      print('DatabaseService: Database already initialized, returning existing instance.');
      return _database!;
    }
    print('DatabaseService: Database not initialized, calling _initDatabase()...');
    _database = await _initDatabase();
    print('DatabaseService: _initDatabase() completed.');
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('DatabaseService: _initDatabase() called.');
    String path;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = '/learnflow_ai.db'; // A logical path for web
    } else {
      path = join(await getDatabasesPath(), 'learnflow_ai.db');
    }
    print('DatabaseService: Database path: $path');

    return await openDatabase(
      path,
      version: 4, // IMPORTANT: Increment version to trigger onUpgrade or onCreate if DB is deleted
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade for schema changes
    );
  }

  Future _onCreate(Database db, int version) async {
    print('DatabaseService: onCreate called. Creating tables...');
    // Create User table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT,
        is_staff INTEGER NOT NULL DEFAULT 0
      )
    ''');
    print('Table "users" created.');

    // Create Student table (UUID as PK, user_id as unique index)
    await db.execute('''
      CREATE TABLE students(
        uuid TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL UNIQUE,
        student_id_code TEXT,
        grade_level TEXT,
        class_name TEXT,
        date_registered TEXT,
        last_device_sync TEXT,
        gender TEXT,
        date_of_birth TEXT,
        school_name TEXT,
        wallet_address TEXT
        -- FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE -- Removed for now to avoid circular dependency issues during creation/upgrade
      )
    ''');
    print('Table "students" created.');

    // Create Lesson table
    await db.execute('''
      CREATE TABLE lessons(
        uuid TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        subject TEXT,
        difficulty_level TEXT,
        version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        lesson_file TEXT,
        prerequisites TEXT
      )
    ''');
    print('Table "lessons" created.');

    // Create Question table
    await db.execute('''
      CREATE TABLE questions(
        uuid TEXT PRIMARY KEY,
        lesson_uuid TEXT NOT NULL,
        question_text TEXT NOT NULL,
        question_type TEXT NOT NULL,
        options TEXT, -- Stored as JSON string
        correct_answer_text TEXT, -- Renamed from correct_answer to match model
        difficulty_level TEXT NOT NULL,
        expected_time_seconds INTEGER,
        ai_generated_feedback TEXT,
        created_at TEXT NOT NULL, -- Added missing columns
        updated_at TEXT NOT NULL, -- Added missing columns
        FOREIGN KEY (lesson_uuid) REFERENCES lessons (uuid) ON DELETE CASCADE
      )
    ''');
    print('Table "questions" created.');

    // Create QuizAttempt table (student_uuid added)
    await db.execute('''
      CREATE TABLE quiz_attempts(
        uuid TEXT PRIMARY KEY,
        student_user_id INTEGER NOT NULL,
        student_uuid TEXT NOT NULL, -- NEW: Add student_uuid column
        student_id_code TEXT,
        question_uuid TEXT NOT NULL,
        submitted_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        score REAL NOT NULL,
        ai_feedback_text TEXT,
        raw_ai_response TEXT,
        attempt_timestamp TEXT NOT NULL,
        synced_at TEXT,
        sync_status TEXT NOT NULL,
        device_id TEXT, -- Made nullable
        lesson_title TEXT,
        question_text_preview TEXT,
        FOREIGN KEY (student_uuid) REFERENCES students (uuid) ON DELETE CASCADE, -- Link to student's UUID
        FOREIGN KEY (question_uuid) REFERENCES questions (uuid) ON DELETE CASCADE
      )
    ''');
    print('Table "quiz_attempts" created.');

    // Create StudentProgress table
    await db.execute('''
      CREATE TABLE student_progress(
        uuid TEXT PRIMARY KEY,
        student_user_id INTEGER UNIQUE,
        overall_progress_data TEXT, -- Stored as JSON string
        last_updated TEXT,
        FOREIGN KEY (student_user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('Table "student_progress" created.');

    print('DatabaseService: All tables created successfully.');
  }

  // Add onUpgrade method to handle schema changes for existing databases
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('DatabaseService: onUpgrade called. Old version: $oldVersion, New version: $newVersion');
    if (oldVersion < 2) {
      // This block would run if upgrading from a version 1 to 2
      // Add expected_time_seconds column to questions table
      await db.execute('ALTER TABLE questions ADD COLUMN expected_time_seconds INTEGER');
      print('DatabaseService: Added expected_time_seconds column to questions table.');
    }
    if (oldVersion < 3) {
      // This block runs if upgrading from version 2 to 3
      // Add student_uuid column to quiz_attempts table
      await db.execute('ALTER TABLE quiz_attempts ADD COLUMN student_uuid TEXT;');
      print('Added student_uuid column to quiz_attempts table.');
      // Update the foreign key constraint if necessary, but direct ALTER TABLE for FK is tricky.
      // For simplicity in development, dropping and recreating tables is often done.
    }
    if (oldVersion < 4) {
      // This block runs if upgrading from version 3 to 4
      print('DatabaseService: Upgrading to version 4. Modifying students, questions and quiz_attempts tables.');

      // Recreate students table to change primary key to UUID
      await db.execute('DROP TABLE IF EXISTS students;');
      print('Dropped old "students" table.');
      await db.execute('''
        CREATE TABLE students(
          uuid TEXT PRIMARY KEY,
          user_id INTEGER NOT NULL UNIQUE,
          student_id_code TEXT,
          grade_level TEXT,
          class_name TEXT,
          date_registered TEXT,
          last_device_sync TEXT,
          gender TEXT,
          date_of_birth TEXT,
          school_name TEXT,
          wallet_address TEXT
          -- FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE -- Removed for now to avoid circular dependency issues during creation/upgrade
        )
      ''');
      print('Recreated "students" table with UUID as PRIMARY KEY.');

      // Recreate questions table to add created_at and updated_at, and rename correct_answer
      await db.execute('DROP TABLE IF EXISTS questions;');
      print('Dropped old "questions" table.');
      await db.execute('''
        CREATE TABLE questions(
          uuid TEXT PRIMARY KEY,
          lesson_uuid TEXT NOT NULL,
          question_text TEXT NOT NULL,
          question_type TEXT NOT NULL,
          options TEXT, -- Stored as JSON string
          correct_answer_text TEXT, -- Renamed from correct_answer to match model
          difficulty_level TEXT NOT NULL,
          expected_time_seconds INTEGER,
          ai_generated_feedback TEXT,
          created_at TEXT NOT NULL, -- Added missing columns
          updated_at TEXT NOT NULL, -- Added missing columns
          FOREIGN KEY (lesson_uuid) REFERENCES lessons (uuid) ON DELETE CASCADE
        )
      ''');
      print('Recreated "questions" table with new columns.');


      // Recreate quiz_attempts to ensure correct FK to new students table and nullable device_id
      await db.execute('DROP TABLE IF EXISTS quiz_attempts;');
      print('Dropped old "quiz_attempts" table.');
      await db.execute('''
        CREATE TABLE quiz_attempts (
          uuid TEXT PRIMARY KEY,
          student_user_id INTEGER NOT NULL,
          student_uuid TEXT NOT NULL, -- Ensure this is here
          student_id_code TEXT,
          question_uuid TEXT NOT NULL,
          submitted_answer TEXT NOT NULL,
          is_correct INTEGER NOT NULL,
          score REAL NOT NULL,
          ai_feedback_text TEXT,
          raw_ai_response TEXT,
          attempt_timestamp TEXT NOT NULL,
          synced_at TEXT,
          sync_status TEXT NOT NULL,
          device_id TEXT, -- Now nullable
          lesson_title TEXT,
          question_text_preview TEXT,
          FOREIGN KEY (student_uuid) REFERENCES students (uuid) ON DELETE CASCADE, -- Link to student's UUID
          FOREIGN KEY (question_uuid) REFERENCES questions (uuid) ON DELETE CASCADE
        )
      ''');
      print('Recreated "quiz_attempts" table with student_uuid FK and nullable device_id.');
    }
    // Add any other schema migrations here for future versions
  }


  // --- User Operations ---
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Student Operations ---
  Future<int> insertStudent(Student student) async {
    final db = await database;
    // Ensure UUID is used as primary key for insertion
    return await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get student by UUID (new primary key)
  Future<Student?> getStudent(String uuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  // Get student by User ID (still useful for lookup)
  Future<Student?> getStudentByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    // Handle null uuid for whereArgs
    if (student.uuid == null || student.uuid.isEmpty) { // uuid is now non-nullable, check for empty
      print('DatabaseService: Cannot update student. Student UUID is null or empty. Attempting insert instead.');
      return await insertStudent(student); // Try to insert if UUID is missing for update
    }
    return await db.update(
      'students',
      student.toMap(),
      where: 'uuid = ?',
      whereArgs: [student.uuid], // student.uuid is now guaranteed non-null here
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteStudent(String uuid) async {
    final db = await database;
    // Delete by UUID (new primary key)
    return await db.delete(
      'students',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  // --- Lesson Operations ---
  Future<int> insertLesson(Lesson lesson) async {
    final db = await database;
    return await db.insert('lessons', lesson.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Lesson>> getLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lessons');
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      return Lesson.fromMap(map);
    });
  }

  Future<Lesson?> getLesson(String uuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lessons',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (maps.isNotEmpty) {
      return Lesson.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateLesson(Lesson lesson) async {
    final db = await database;
    return await db.update(
      'lessons',
      lesson.toMap(),
      where: 'uuid = ?',
      whereArgs: [lesson.uuid],
    );
  }

  Future<int> deleteLesson(String uuid) async {
    final db = await database;
    return await db.delete(
      'lessons',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  // --- Question Operations ---
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    final Map<String, dynamic> data = question.toMap();
    // Ensure options are JSON encoded if not null
    if (question.options != null) {
      data['options'] = jsonEncode(question.options);
    }
    return await db.insert('questions', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Question>> getQuestionsForLesson(String lessonUuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'lesson_uuid = ?',
      whereArgs: [lessonUuid],
    );
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      // Decode options from JSON string back to List<String>
      if (map['options'] != null && map['options'] is String) {
        try {
          map['options'] = List<String>.from(jsonDecode(map['options']));
        } catch (e) {
          print('Error decoding options JSON: $e for question ${map['uuid']}');
          map['options'] = <String>[]; // Default to empty list on error
        }
      } else {
        map['options'] = <String>[]; // Ensure it's a list even if null initially
      }
      return Question.fromMap(map);
    });
  }

  Future<Question?> getQuestion(String uuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (maps.isNotEmpty) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
      // Decode options from JSON string back to List<String>
      if (map['options'] != null && map['options'] is String) {
        try {
          map['options'] = List<String>.from(jsonDecode(map['options']));
        } catch (e) {
          print('Error decoding options JSON: $e for question ${map['uuid']}');
          map['options'] = <String>[];
        }
      } else {
        map['options'] = <String>[];
      }
      return Question.fromMap(map);
    }
    return null;
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    final Map<String, dynamic> data = question.toMap();
    // Ensure options are JSON encoded if not null
    if (question.options != null) {
      data['options'] = jsonEncode(question.options);
    }
    return await db.update(
      'questions',
      data,
      where: 'uuid = ?',
      whereArgs: [question.uuid],
    );
  }

  Future<int> deleteQuestion(String uuid) async {
    final db = await database;
    return await db.delete(
      'questions',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  // --- QuizAttempt Operations ---
  Future<int> insertQuizAttempt(QuizAttempt attempt) async {
    final db = await database;
    final Map<String, dynamic> data = attempt.toMap();
    // Ensure rawAiResponse is JSON encoded if not null
    if (attempt.rawAiResponse != null) {
      data['raw_ai_response'] = jsonEncode(attempt.rawAiResponse);
    }
    if (data['student_uuid'] == null) {
      print('DatabaseService: Warning: student_uuid is null for quiz attempt ${attempt.uuid}. This might cause issues.');
    }
    return await db.insert('quiz_attempts', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<QuizAttempt>> getQuizAttemptsByStudent(int studentUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_attempts',
      where: 'student_user_id = ?',
      whereArgs: [studentUserId],
      orderBy: 'attempt_timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      // Decode raw_ai_response from JSON string
      if (map['raw_ai_response'] != null && map['raw_ai_response'] is String) {
        try {
          map['raw_ai_response'] = jsonDecode(map['raw_ai_response']);
        } catch (e) {
          print('Error decoding raw_ai_response JSON: $e for attempt ${map['uuid']}');
          map['raw_ai_response'] = null; // Default to null on error
        }
      }
      return QuizAttempt.fromMap(map);
    });
  }

  Future<List<QuizAttempt>> getPendingQuizAttempts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_attempts',
      where: 'sync_status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'attempt_timestamp ASC',
    );
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      // Decode raw_ai_response from JSON string
      if (map['raw_ai_response'] != null && map['raw_ai_response'] is String) {
        try {
          map['raw_ai_response'] = jsonDecode(map['raw_ai_response']);
        } catch (e) {
          print('Error decoding raw_ai_response JSON: $e for attempt ${map['uuid']}');
          map['raw_ai_response'] = null; // Default to null on error
        }
      }
      return QuizAttempt.fromMap(map);
    });
  }

  Future<QuizAttempt?> getQuizAttempt(String uuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_attempts',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (maps.isNotEmpty) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
      // Decode raw_ai_response from JSON string
      if (map['raw_ai_response'] != null && map['raw_ai_response'] is String) {
        try {
          map['raw_ai_response'] = jsonDecode(map['raw_ai_response']);
        } catch (e) {
          print('Error decoding raw_ai_response JSON: $e for attempt ${map['uuid']}');
          map['raw_ai_response'] = null; // Default to null on error
        }
      }
      return QuizAttempt.fromMap(map);
    }
    return null;
  }

  Future<int> updateQuizAttempt(QuizAttempt attempt) async {
    final db = await database;
    final Map<String, dynamic> data = attempt.toMap();
    // Ensure rawAiResponse is JSON encoded if not null
    if (attempt.rawAiResponse != null) {
      data['raw_ai_response'] = jsonEncode(attempt.rawAiResponse);
    }
    return await db.update(
      'quiz_attempts',
      data,
      where: 'uuid = ?',
      whereArgs: [attempt.uuid],
    );
  }

  Future<int> deleteQuizAttempt(String uuid) async {
    final db = await database;
    return await db.delete(
      'quiz_attempts',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  // --- CRUD Operations for StudentProgress ---
  Future<int> insertStudentProgress(StudentProgress progress) async {
    final db = await database;
    final Map<String, dynamic> data = progress.toMap();
    if (progress.overallProgressData != null) {
      data['overall_progress_data'] = jsonEncode(progress.overallProgressData);
    }
    return await db.insert('student_progress', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<StudentProgress?> getStudentProgress(int studentUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'student_progress',
      where: 'student_user_id = ?',
      whereArgs: [studentUserId],
    );
    if (maps.isNotEmpty) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
      if (map['overall_progress_data'] != null && map['overall_progress_data'] is String) {
        try {
          map['overall_progress_data'] = jsonDecode(map['overall_progress_data']);
        } catch (e) {
          print('Error decoding overall_progress_data JSON: $e for student ${map['student_user_id']}');
          map['overall_progress_data'] = {}; // Default to empty map on error
        }
      } else {
        map['overall_progress_data'] = {}; // Ensure it's a map even if null
      }
      return StudentProgress.fromMap(map);
    }
    return null;
  }

  Future<int> updateStudentProgress(StudentProgress progress) async {
    final db = await database;
    final Map<String, dynamic> data = progress.toMap();
    if (progress.overallProgressData != null) {
      data['overall_progress_data'] = jsonEncode(progress.overallProgressData);
    }
    // Handle null uuid for whereArgs
    if (progress.uuid == null || progress.uuid!.isEmpty) {
      print('DatabaseService: Cannot update student progress. UUID is null or empty. Attempting insert instead.');
      return await insertStudentProgress(progress); // Try to insert if UUID is missing for update
    }
    return await db.update(
      'student_progress',
      data,
      where: 'uuid = ?',
      whereArgs: [progress.uuid],
    );
  }

  Future<int> deleteStudentProgress(String uuid) async {
    final db = await database;
    return await db.delete(
      'student_progress',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }
}
