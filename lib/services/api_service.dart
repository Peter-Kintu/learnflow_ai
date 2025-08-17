// learnflow_ai/flutter_app/lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String _baseUrl = 'https://africana-ntgr.onrender.com/api/v1';
  static const String _localUrl = 'http://10.0.2.2:8000/api/v1';

  String get baseUrl => kIsWeb ? _baseUrl : _localUrl;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> getHeaders({String? token}) async {
    token ??= await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<User?> fetchCurrentUser() async {
    final url = Uri.parse('$baseUrl/auth/user/');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login/');
    final headers = await getHeaders(token: null);
    final body = json.encode({
      'username': username,
      'password': password,
    });
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return {'success': true, 'data': data};
    } else {
      final error = json.decode(response.body);
      return {'success': false, 'error': error.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, Map<String, dynamic> studentData) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    final headers = await getHeaders(token: null);
    final body = json.encode({
      'username': username,
      'email': email,
      'password': password,
      'student_data': studentData,
    });
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return {'success': true, 'data': data};
    } else {
      final error = json.decode(response.body);
      return {'success': false, 'error': error.toString()};
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<List<Lesson>> getLessons() async {
    final url = Uri.parse('$baseUrl/lessons/');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Lesson.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load lessons: ${response.statusCode}');
    }
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final url = Uri.parse('$baseUrl/lessons/');
    final headers = await getHeaders();
    final body = json.encode(lesson.toJson());
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 201) {
      return Lesson.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create lesson: ${response.body}');
    }
  }

  Future<List<Question>> getQuestionsForLesson(String lessonUuid) async {
    final url = Uri.parse('$baseUrl/questions/?lesson_uuid=$lessonUuid');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load questions: ${response.statusCode}');
    }
  }

  Future<Question> addQuestion(Question question) async {
    final url = Uri.parse('$baseUrl/questions/');
    final headers = await getHeaders();
    final body = json.encode(question.toJson());
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 201) {
      return Question.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add question: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> saveQuizAttempt(QuizAttempt attempt) async {
    final url = Uri.parse('$baseUrl/quiz-attempts/');
    final headers = await getHeaders();
    final body = json.encode(attempt.toJson());
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to save quiz attempt: ${response.statusCode}');
    }
  }

  Future<Student?> fetchCurrentStudentProfile() async {
    final url = Uri.parse('$baseUrl/students/current/');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return Student.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<void> downloadQuizAttemptsReport() async {
    final url = Uri.parse('$baseUrl/quiz-attempts/export_csv/');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      // TODO: Handle file download and saving to a file.
      // The response.body contains the CSV data.
      // You'll need to use packages like `path_provider` and `flutter_file_saver`
      // or similar to save the file to the user's device.
      print('CSV report downloaded successfully.');
    } else {
      throw Exception('Failed to download report: ${response.statusCode}');
    }
  }
}