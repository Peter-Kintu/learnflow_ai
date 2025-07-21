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
      print('DatabaseService:_initDatabase: Attempting to get databases path...');
      final databasePath = await getDatabasesPath();
      print('DatabaseService:_initDatabase: Got databases path: $databasePath');
      final path = join(databasePath, 'learnflow_ai.db'); // Database file name
      print('DatabaseService:_initDatabase: Full database path: $path');

      print('DatabaseService:_initDatabase: Attempting to open database...');
      final db = await openDatabase(
        path,
        version: 1, // Database version
        onCreate: _onCreate, // Callback when the database is first created
        onUpgrade: _onUpgrade, // Callback when the database needs to be upgraded
      );
      print('DatabaseService:_initDatabase: Database opened successfully.');
      return db;
    } catch (e, stacktrace) {
      print('DatabaseService ERROR in _initDatabase: $e');
      print('Stacktrace: $stacktrace');
      rethrow; // Re-throw to make the error visible in the Flutter console
    }
  }

  // Create tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    print('DatabaseService: _onCreate called. Creating tables...');

    try {
      // Create User table
      print('DatabaseService:_onCreate: Creating "users" table...');
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          email TEXT,
          is_staff INTEGER NOT NULL DEFAULT 0
        )
      ''');
      print('DatabaseService:_onCreate: Table "users" created.');

      // Create Student table
      print('DatabaseService:_onCreate: Creating "students" table...');
      await db.execute('''
        CREATE TABLE students(
          user_id INTEGER PRIMARY KEY,
          student_id_code TEXT UNIQUE,
          date_registered TEXT NOT NULL,
          date_of_birth TEXT,
          gender TEXT,
          grade_level TEXT,
          class_name TEXT,
          school_name TEXT,
          last_device_sync TEXT
        )
      ''');
      print('DatabaseService:_onCreate: Table "students" created.');

      // Create Lesson table
      print('DatabaseService:_onCreate: Creating "lessons" table...');
      await db.execute('''
        CREATE TABLE lessons(
          id INTEGER PRIMARY KEY, -- Added ID for local storage consistency with Django
          uuid TEXT UNIQUE NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          subject TEXT,
          difficulty_level TEXT,
          prerequisites TEXT, -- Stored as JSON string
          lesson_file TEXT, -- Changed from lesson_file_url to lesson_file for consistency
          version INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      print('DatabaseService:_onCreate: Table "lessons" created.');

      // Create Question table
      print('DatabaseService:_onCreate: Creating "questions" table...');
      await db.execute('''
        CREATE TABLE questions(
          uuid TEXT PRIMARY KEY,
          lesson_uuid TEXT NOT NULL,
          lesson_id INTEGER, -- Store Django's integer ID for linking
          question_text TEXT NOT NULL,
          question_type TEXT NOT NULL,
          options TEXT, -- Stored as JSON string
          correct_answer_text TEXT,
          difficulty_level TEXT,
          expected_time_seconds INTEGER,
          created_at TEXT NOT NULL
        )
      ''');
      print('DatabaseService:_onCreate: Table "questions" created.');

      // Create QuizAttempt table
      print('DatabaseService:_onCreate: Creating "quiz_attempts" table...');
      await db.execute('''
        CREATE TABLE quiz_attempts(
          uuid TEXT PRIMARY KEY,
          student_user_id INTEGER NOT NULL,
          student_id_code TEXT, -- ADDED: student_id_code for Django compatibility
          question_uuid TEXT NOT NULL,
          submitted_answer TEXT NOT NULL,
          is_correct INTEGER, -- SQLite stores bool as int (1 for true, 0 for false, NULL for null)
          score REAL, -- Changed to REAL for double
          ai_feedback_text TEXT,
          raw_ai_response TEXT, -- Stored as JSON string
          attempt_timestamp TEXT NOT NULL,
          synced_at TEXT,
          sync_status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'SYNCED', 'FAILED'
          device_id TEXT
        )
      ''');
      print('DatabaseService:_onCreate: Table "quiz_attempts" created.');

      // Create StudentProgress table
      print('DatabaseService:_onCreate: Creating "student_progress" table...');
      await db.execute('''
        CREATE TABLE student_progress(
          uuid TEXT PRIMARY KEY,
          student_user_id INTEGER NOT NULL,
          overall_progress_data TEXT, -- Stored as JSON string
          last_updated TEXT NOT NULL,
          completed_lessons TEXT, -- JSON string of completed lesson UUIDs
          quiz_scores TEXT -- JSON string of quiz scores per lesson/topic
        )
      ''');
      print('DatabaseService:_onCreate: Table "student_progress" created.');

    } catch (e, stacktrace) {
      print('DatabaseService ERROR in _onCreate: Failed to create tables: $e');
      print('Stacktrace: $stacktrace');
      rethrow;
    }
    print('DatabaseService: All tables created successfully.');
  }

  // Handle database upgrades (e.g., adding new tables or columns)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('DatabaseService: Database upgraded from version $oldVersion to $newVersion');
    // Implement migration logic here if your database schema changes in future versions.
    // For example:
    // if (oldVersion < 2) {
    //   await db.execute("ALTER TABLE lessons ADD COLUMN new_column TEXT;");
    // }
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

  Future<Student?> getStudentByStudentIdCode(String studentIdCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'student_id_code = ?',
      whereArgs: [studentIdCode],
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

  // --- CRUD Operations for Lesson ---
  Future<int> insertLesson(Lesson lesson) async {
    final db = await database;
    return await db.insert('lessons', lesson.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Lesson>> getAllLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lessons');
    return List.generate(maps.length, (i) {
      return Lesson.fromMap(maps[i]);
    });
  }

  Future<Lesson?> getLessonByUuid(String uuid) async {
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
    return await db.insert('questions', question.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Question>> getQuestionsForLesson(String lessonUuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'lesson_uuid = ?',
      whereArgs: [lessonUuid],
      orderBy: 'created_at ASC', // Order by creation time
    );
    return List.generate(maps.length, (i) {
      return Question.fromMap(maps[i]);
    });
  }

  Future<Question?> getQuestionByUuid(String uuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (maps.isNotEmpty) {
      return Question.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    return await db.update(
      'questions',
      question.toMap(),
      where: 'uuid = ?',
      whereArgs: [question.uuid],
    );
  }

  // --- CRUD Operations for QuizAttempt ---
  Future<int> insertQuizAttempt(QuizAttempt attempt) async {
    final db = await database;
    return await db.insert('quiz_attempts', attempt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<QuizAttempt>> getAllQuizAttemptsForStudent(int studentUserId) async {
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
    return await db.insert('student_progress', progress.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<StudentProgress?> getStudentProgress(int studentUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'student_progress',
      where: 'student_user_id = ?',
      whereArgs: [studentUserId],
    );
    if (maps.isNotEmpty) {
      return StudentProgress.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateStudentProgress(StudentProgress progress) async {
    final db = await database;
    return await db.update(
      'student_progress',
      progress.toMap(),
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

  // Close the database (important for clean shutdown)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Clear the instance
  }
}
