// learnflow_ai/flutter_app/lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/models/student_progress.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // IMPORTANT: For deployment, replace localhost/10.0.2.2 with your live Render URL.
  // The base URL for your Django backend API.
  // Use your Render.com service URL here.
  static const String _baseUrl = 'https://africana-ntgr.onrender.com/api'; // UPDATED TO YOUR RENDER URL

  String? _authToken;
  int? _currentUserId;

  static const String _demoAuthToken = '7a22cba24bac92bde8419d8a1fdee152f921188c';
  static const int _demoUserId = 5; // User ID associated with the demo token

  ApiService() {
    _loadAuthToken();
  }

  // --- Utility Methods ---
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    _currentUserId = prefs.getInt('currentUserId');

    // If no token is saved (first run or after logout), use the demo token and ID
    if (_authToken == null) {
      _authToken = _demoAuthToken;
      _currentUserId = _demoUserId;
      // Optionally save them for persistence across restarts in demo mode
      await prefs.setString('authToken', _authToken!);
      await prefs.setInt('currentUserId', _currentUserId!);
      print('API Service: Using DEMO Auth Token and User ID: $_authToken, User ID: $_currentUserId');
    } else {
      print('API Service: Loaded Auth Token: $_authToken, User ID: $_currentUserId');
    }
  }

  Future<void> _saveAuthToken(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setInt('currentUserId', userId);
    _authToken = token;
    _currentUserId = userId;
    print('API Service: Saved Auth Token: $_authToken, User ID: $_currentUserId');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('currentUserId');
    _authToken = null;
    _currentUserId = null;
    print('API Service: Cleared Auth Token and User ID.');
    try {
      final url = Uri.parse('$_baseUrl/auth/logout/');
      await http.post(url, headers: _getHeaders());
    } catch (e) {
      print('Error calling Django logout: $e');
    }
  }

  Future<void> _ensureToken() async {
    if (_authToken == null || _currentUserId == null) { // Ensure both token and ID are present
      await _loadAuthToken();
    }
  }

  Map<String, String> _getHeaders({bool includeAuth = true, bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  // --- Auth Endpoints ---
  Future<Map<String, dynamic>> registerUser(String username, String email, String password, {String? studentIdCode}) async {
    final url = Uri.parse('$_baseUrl/auth/register/');
    final body = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      if (studentIdCode != null) 'student_id_code': studentIdCode,
    });
    try {
      final response = await http.post(url, headers: _getHeaders(includeAuth: false), body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _saveAuthToken(responseData['token'], responseData['user_id']);
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during registration: $e'};
    }
  }

  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login/');
    final body = jsonEncode({'username': username, 'password': password});
    try {
      final response = await http.post(url, headers: _getHeaders(includeAuth: false), body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveAuthToken(responseData['token'], responseData['user_id']);
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during login: $e'};
    }
  }

  // --- User/Student Endpoints ---
  Future<User?> fetchCurrentUser() async {
    await _ensureToken();
    if (_authToken == null || _currentUserId == null) return null;

    final url = Uri.parse('$_baseUrl/students/$_currentUserId/');
    print('API Service: Fetching current user/student profile from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch current user response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final studentData = jsonDecode(response.body);
        return User.fromJson(studentData['user']);
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for current user. Token might be invalid or expired.');
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Fetch Current User Error: $e');
      return null;
    }
  }

  Future<Student?> fetchCurrentStudentProfile() async {
    await _ensureToken();
    if (_authToken == null || _currentUserId == null) return null;

    final url = Uri.parse('$_baseUrl/students/$_currentUserId/');
    print('API Service: Fetching current student profile from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch current student profile response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return Student.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for student profile. Token might be invalid or expired.');
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Fetch Current Student Profile Error: $e');
      return null;
    }
  }

  Future<int?> getCurrentUserId() async {
    await _ensureToken();
    return _currentUserId;
  }

  // --- Lesson Endpoints ---
  Future<List<Lesson>> fetchLessons() async {
    await _ensureToken();
    if (_authToken == null) return [];

    final url = Uri.parse('$_baseUrl/lessons/');
    print('API Service: Fetching lessons from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch lessons response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['results'];
        return data.map((json) => Lesson.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for lessons. Token might be invalid or expired.');
        await logout();
        return [];
      }
      return [];
    } catch (e) {
      print('Fetch Lessons Error: $e');
      return [];
    }
  }

  Future<Lesson?> createLesson(Lesson lesson) async {
    await _ensureToken();
    if (_authToken == null) return null;

    final url = Uri.parse('$_baseUrl/lessons/');
    print('API Service: Creating lesson: ${lesson.toJson()}');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(lesson.toJson()),
      );
      print('API Service: Create lesson response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        return Lesson.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for create lesson. Token might be invalid or expired.');
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Create Lesson Error: $e');
      return null;
    }
  }

  // --- Question Endpoints ---
  Future<List<Question>> fetchQuestionsForLesson(String lessonUuid) async {
    await _ensureToken();
    if (_authToken == null) return [];

    final url = Uri.parse('$_baseUrl/questions/?lesson__uuid=$lessonUuid');
    print('API Service: Fetching questions for lesson $lessonUuid from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch questions response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['results'];
        return data.map((json) => Question.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for questions. Token might be invalid or expired.');
        await logout();
        return [];
      }
      return [];
    } catch (e) {
      print('Fetch Questions Error: $e');
      return [];
    }
  }

  Future<Question?> createQuestion(Question question) async {
    await _ensureToken();
    if (_authToken == null) return null;

    final url = Uri.parse('$_baseUrl/questions/');
    print('API Service: Creating question: ${question.toJson()}');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(question.toJson()),
      );
      print('API Service: Create question response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        return Question.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for create question. Token might be invalid or expired.');
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Create Question Error: $e');
      return null;
    }
  }

  // --- QuizAttempt Endpoints ---
  Future<Map<String, dynamic>> uploadQuizAttempts(List<QuizAttempt> attempts) async {
    await _ensureToken();
    if (_authToken == null) {
      return {'success': false, 'message': 'Authentication token not available.'};
    }

    final url = Uri.parse('$_baseUrl/quiz-attempts/bulk_upload/');
    final List<Map<String, dynamic>> attemptsJson = attempts.map((a) => a.toJson()).toList();
    print('API Service: Uploading quiz attempts: ${attemptsJson.length} attempts');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(attemptsJson),
      );
      print('API Service: Bulk upload response status: ${response.statusCode}, body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 207) {
        return {'success': true, 'message': 'Upload successful', 'data': responseData};
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for bulk upload. Token might be invalid or expired.');
        await logout();
        return {'success': false, 'message': 'Authentication failed. Please log in again.'};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Bulk upload failed', 'data': responseData};
      }
    } catch (e) {
      print('Bulk Upload Error: $e');
      return {'success': false, 'message': 'Network error during bulk upload: $e'};
    }
  }

  // --- Student Progress Endpoints ---
  Future<StudentProgress?> fetchStudentProgress(int studentUserId) async {
    await _ensureToken();
    if (_authToken == null) return null;

    final url = Uri.parse('$_baseUrl/student-progress/$studentUserId/');
    print('API Service: Fetching student progress for user ID: $studentUserId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch student progress response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return StudentProgress.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for student progress. Token might be invalid or expired.');
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Fetch Student Progress Error: $e');
      return null;
    }
  }

  Future<StudentProgress?> updateStudentProgress(StudentProgress progress) async {
    await _ensureToken();
    if (_authToken == null) return null;

    final url = Uri.parse('$_baseUrl/student-progress/${progress.studentUserId}/');
    print('API Service: Updating student progress for user ID: ${progress.studentUserId}');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(progress.toJson()),
      );
      print('API Service: Update student progress response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return StudentProgress.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for student progress update. Token might be invalid or expired.');
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Update Student Progress Error: $e');
      return null;
    }
  }

  // --- Wallet Endpoints ---
  Future<Map<String, dynamic>> registerWallet(String walletAddress) async {
    await _ensureToken();
    if (_authToken == null || _currentUserId == null) {
      return {'success': false, 'message': 'Authentication token or user ID not available.'};
    }

    final url = Uri.parse('$_baseUrl/wallets/');
    final body = jsonEncode({
      'student': _currentUserId,
      'address': walletAddress,
    });
    print('API Service: Registering wallet: $body');
    try {
      final response = await http.post(url, headers: _getHeaders(), body: body);
      final responseData = jsonDecode(response.body);
      print('API Service: Register wallet response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Wallet registered successfully'};
      } else {
        return {'success': false, 'message': responseData['address']?.join(', ') ?? responseData['detail'] ?? 'Failed to register wallet'};
      }
    } catch (e) {
      print('Register Wallet Error: $e');
      return {'success': false, 'message': 'Network error during wallet registration: $e'};
    }
  }

  Future<Map<String, dynamic>> updateWallet(String walletAddress) async {
    await _ensureToken();
    if (_authToken == null || _currentUserId == null) {
      return {'success': false, 'message': 'Authentication token or user ID not available.'};
    }

    final url = Uri.parse('$_baseUrl/wallets/$_currentUserId/');
    final body = jsonEncode({
      'student': _currentUserId,
      'address': walletAddress,
    });
    print('API Service: Updating wallet: $body');
    try {
      final response = await http.put(url, headers: _getHeaders(), body: body);
      final responseData = jsonDecode(response.body);
      print('API Service: Update wallet response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Wallet updated successfully'};
      } else {
        return {'success': false, 'message': responseData['address']?.join(', ') ?? responseData['detail'] ?? 'Failed to update wallet'};
      }
    } catch (e) {
      print('Update Wallet Error: $e');
      return {'success': false, 'message': 'Network error during wallet update: $e'};
    }
  }

  Future<Map<String, dynamic>> getLearnFlowTokenBalance() async {
    await _ensureToken();
    if (_authToken == null) {
      return {'success': false, 'message': 'Authentication token not available.', 'balance': 0.0};
    }

    final url = Uri.parse('$_baseUrl/wallets/balance/');
    print('API Service: Fetching LFT balance from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      final responseData = jsonDecode(response.body);
      print('API Service: Fetch LFT balance response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return {'success': true, 'balance': responseData['balance']?.toDouble() ?? 0.0};
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for LFT balance. Token might be invalid or expired.');
        await logout();
        return {'success': false, 'message': 'Authentication failed. Please log in again.', 'balance': 0.0};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to fetch balance', 'balance': 0.0};
      }
    } catch (e) {
      print('Fetch LFT Balance Error: $e');
      return {'success': false, 'message': 'Network error during balance fetch: $e', 'balance': 0.0};
    }
  }
}
