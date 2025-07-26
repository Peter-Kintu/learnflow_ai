// learnflow_ai/flutter_app/lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/models/student_progress.dart';
import 'dart:convert'; // For JSON encoding/decoding for complex types

class DatabaseService {
  static Database? _database; // Private instance of the database
  static final DatabaseService instance = DatabaseService._constructor(); // Singleton instance

  // Private constructor for the singleton pattern
  DatabaseService._constructor();

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) {
      print('DatabaseService: Database already initialized, returning existing instance.');
      return _database!;
    }
    print('DatabaseService: Database not initialized, calling _initDatabase()...');
    _database = await _initDatabase(); // Initialize if null
    print('DatabaseService: _initDatabase() completed.');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    try {
      print('DatabaseService: _initDatabase() called.');
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'learnflow_ai.db');
      print('DatabaseService: Database path: $path');

      return await openDatabase(
        path,
        version: 1, // Increment version if you make schema changes in the future
        onCreate: (db, version) async {
          print('DatabaseService: onCreate called. Creating tables...');
          // Create User table
          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY,
              username TEXT,
              email TEXT,
              is_staff INTEGER
            )
          ''');
          print('Table "users" created.');

          // Create Student table
          await db.execute('''
            CREATE TABLE students(
              user_id INTEGER PRIMARY KEY,
              student_id_code TEXT,
              grade_level TEXT,
              class_name TEXT,
              date_registered TEXT,
              last_device_sync TEXT,
              gender TEXT,
              date_of_birth TEXT,
              school_name TEXT,
              wallet_address TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          print('Table "students" created.');

          // Create Lesson table
          await db.execute('''
            CREATE TABLE lessons(
              uuid TEXT PRIMARY KEY,
              title TEXT,
              description TEXT,
              subject TEXT,
              difficulty_level TEXT,
              version INTEGER,
              created_at TEXT,
              updated_at TEXT,
              lesson_file TEXT -- ADDED THIS COLUMN
            )
          ''');
          print('Table "lessons" created.');

          // Create Question table
          await db.execute('''
            CREATE TABLE questions(
              uuid TEXT PRIMARY KEY,
              lesson_uuid TEXT,
              question_text TEXT,
              question_type TEXT,
              options TEXT, -- Stored as JSON string
              correct_answer TEXT,
              difficulty_level TEXT,
              ai_generated_feedback TEXT,
              FOREIGN KEY (lesson_uuid) REFERENCES lessons (uuid) ON DELETE CASCADE
            )
          ''');
          print('Table "questions" created.');

          // Create QuizAttempt table
          await db.execute('''
            CREATE TABLE quiz_attempts(
              uuid TEXT PRIMARY KEY,
              student_user_id INTEGER,
              student_id_code TEXT,
              question_uuid TEXT,
              submitted_answer TEXT,
              is_correct INTEGER,
              score REAL,
              ai_feedback_text TEXT,
              raw_ai_response TEXT,
              attempt_timestamp TEXT,
              synced_at TEXT,
              sync_status TEXT,
              device_id TEXT,
              lesson_title TEXT,
              question_text_preview TEXT,
              FOREIGN KEY (student_user_id) REFERENCES students (user_id) ON DELETE CASCADE,
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
              FOREIGN KEY (student_user_id) REFERENCES students (user_id) ON DELETE CASCADE
            )
          ''');
          print('Table "student_progress" created.');

          print('DatabaseService: All tables created successfully.');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print('DatabaseService: onUpgrade called. Old version: $oldVersion, New version: $newVersion');
          // In a real app, you'd handle migrations here.
          // For now, we are recommending clearing app data to force onCreate.
        },
      );
    } catch (e) {
      print('DatabaseService: Error initializing database: $e');
      rethrow; // Rethrow the error to be caught higher up
    }
  }

  // --- CRUD Operations for User ---
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
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

  // --- CRUD Operations for Student ---
  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Student?> getStudent(int userId) async {
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
    return await db.update(
      'students',
      student.toMap(),
      where: 'user_id = ?',
      whereArgs: [student.userId],
    );
  }

  Future<int> deleteStudent(int userId) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // --- CRUD Operations for Lesson ---
  Future<int> insertLesson(Lesson lesson) async {
    final db = await database;
    return await db.insert('lessons', lesson.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Lesson>> getLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lessons');
    return List.generate(maps.length, (i) {
      return Lesson.fromMap(maps[i]);
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

  // --- CRUD Operations for Question ---
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    // Convert options list to JSON string for storage
    final Map<String, dynamic> data = question.toMap();
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
      // Decode options JSON string back to List<String>
      final Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      if (map['options'] != null && map['options'] is String) {
        try {
          map['options'] = List<String>.from(jsonDecode(map['options']));
        } catch (e) {
          print('Error decoding options JSON: $e for question ${map['uuid']}');
          map['options'] = <String>[]; // Default to empty list on error
        }
      } else {
        map['options'] = <String>[]; // Ensure it's a list even if null
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

  // --- CRUD Operations for QuizAttempt ---
  Future<int> insertQuizAttempt(QuizAttempt attempt) async {
    final db = await database;
    return await db.insert('quiz_attempts', attempt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
      return QuizAttempt.fromMap(maps[i]);
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
      return QuizAttempt.fromMap(maps[i]);
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
      return QuizAttempt.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuizAttempt(QuizAttempt attempt) async {
    final db = await database;
    return await db.update(
      'quiz_attempts',
      attempt.toMap(),
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
    // Convert overall_progress_data to JSON string for storage
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
      // Decode overall_progress_data JSON string back to Map
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
