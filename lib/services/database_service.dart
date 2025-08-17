// learnflow_ai/flutter_app/lib/services/database_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/student_progress.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      final database = await openDatabase('learnflow_ai.db');
      return database;
    } else {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'learnflow_ai.db');
      return openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        username TEXT,
        email TEXT,
        is_staff INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE students(
        uuid TEXT PRIMARY KEY,
        user_id INTEGER,
        student_id_code TEXT,
        grade_level TEXT,
        class_name TEXT,
        gender TEXT,
        date_registered TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE lessons(
        uuid TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        subject TEXT,
        difficulty_level TEXT,
        version INTEGER,
        cover_image_url TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE questions(
        uuid TEXT PRIMARY KEY,
        lesson_uuid TEXT,
        question_text TEXT,
        question_type TEXT,
        options TEXT,
        correct_answer_text TEXT,
        difficulty_level TEXT,
        expected_time_seconds INTEGER,
        ai_generated_feedback TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (lesson_uuid) REFERENCES lessons (uuid) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE quiz_attempts(
        uuid TEXT PRIMARY KEY,
        student_uuid TEXT,
        question_uuid TEXT,
        attempted_at TEXT,
        submitted_answer TEXT,
        is_correct INTEGER,
        time_spent_seconds INTEGER,
        device_attempt_id TEXT,
        FOREIGN KEY (student_uuid) REFERENCES students (uuid) ON DELETE CASCADE,
        FOREIGN KEY (question_uuid) REFERENCES questions (uuid) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE student_progress(
        uuid TEXT PRIMARY KEY,
        student_uuid TEXT,
        lesson_uuid TEXT,
        last_attempt_date TEXT,
        completion_percentage REAL,
        total_score INTEGER,
        FOREIGN KEY (student_uuid) REFERENCES students (uuid) ON DELETE CASCADE,
        FOREIGN KEY (lesson_uuid) REFERENCES lessons (uuid) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
    }
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'is_staff': user.isStaff ? 1 : 0,
      },
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
      final data = maps.first;
      return User(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        isStaff: data['is_staff'] == 1,
      );
    }
    return null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('students');
    await db.delete('lessons');
    await db.delete('questions');
    await db.delete('quiz_attempts');
    await db.delete('student_progress');
  }

  Future<void> insertLessons(List<Lesson> lessons) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var lesson in lessons) {
        batch.insert(
          'lessons',
          lesson.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Lesson>> getLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lessons');
    return List.generate(maps.length, (i) {
      return Lesson.fromJson(maps[i]);
    });
  }

  Future<void> insertQuestions(List<Question> questions) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var question in questions) {
        batch.insert(
          'questions',
          question.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Question>> getQuestionsForLesson(String lessonUuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'lesson_uuid = ?',
      whereArgs: [lessonUuid],
    );
    return List.generate(maps.length, (i) {
      final json = maps[i];
      if (json['options'] != null) {
        final optionsJson = jsonDecode(json['options'] as String);
        json['options'] = optionsJson;
      }
      return Question.fromJson(json);
    });
  }
}