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
  // The base URL for your Django backend API.
  // This should always point to your live Render.com service URL for deployed apps.
  static const String _baseUrl = 'https://africana-ntgr.onrender.com/api';

  String? _authToken;
  int? _currentUserId; // This will store the ID of the logged-in user

  ApiService() {
    _loadAuthToken(); // Load token and user ID on service initialization
  }

  // --- Utility Methods ---
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    _currentUserId = prefs.getInt('currentUserId'); // Load stored user ID
    print('API Service: Loaded token: $_authToken, User ID: $_currentUserId');
  }

  Future<void> _saveAuthToken(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setInt('currentUserId', userId); // Save user ID
    _authToken = token;
    _currentUserId = userId;
    print('API Service: Saved token and User ID: $userId');
  }

  Future<void> logout() async {
    // Attempt to invalidate token on server first
    if (_authToken != null) {
      final url = Uri.parse('$_baseUrl/auth/logout/');
      try {
        final response = await http.post(url, headers: _getHeaders());
        if (response.statusCode == 204 || response.statusCode == 401) {
          print('API Service: Server logout successful or token already invalid.');
        } else {
          print('API Service: Server logout failed with status: ${response.statusCode}, body: ${response.body}');
        }
      } catch (e) {
        print('API Service: Error during server logout: $e');
      }
    }

    // Clear local storage regardless of server response
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('currentUserId'); // Clear user ID
    _authToken = null;
    _currentUserId = null;
    print('API Service: Local auth token and user ID cleared.');
  }

  // Updated _getHeaders to ensure correct Content-Type for all requests
  Map<String, String> _getHeaders({bool includeAuth = true, String contentType = 'application/json'}) {
    final headers = <String, String>{
      'Content-Type': contentType,
      'Accept': 'application/json',
    };
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  // This method ensures the auth token and user ID are loaded before use.
  Future<void> _ensureToken() async {
    if (_authToken == null || _currentUserId == null) {
      await _loadAuthToken();
    }
  }

  Future<int?> getCurrentUserId() async {
    await _ensureToken();
    return _currentUserId;
  }

  // --- Auth Endpoints ---
  Future<Map<String, dynamic>> registerUser(String username, String password, {required String email, String? studentIdCode, String? gender}) async {
    final url = Uri.parse('$_baseUrl/auth/register/');
    final body = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      if (studentIdCode != null) 'student_id_code': studentIdCode,
      if (gender != null) 'gender': gender,
    });
    try {
      final response = await http.post(url, headers: _getHeaders(includeAuth: false), body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _saveAuthToken(responseData['token'], responseData['user_id']);
        return {'success': true, 'message': 'Registration successful', 'user_id': responseData['user_id']};
      } else {
        print('API Service: Register failed - Status: ${response.statusCode}, Body: ${response.body}');
        return {'success': false, 'message': responseData['error'] ?? responseData.toString() ?? 'Registration failed'};
      }
    } catch (e) {
      print('API Service: Register Error: $e');
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
        return {'success': true, 'message': 'Login successful', 'user_id': responseData['user_id'], 'username': responseData['username']};
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
    if (_authToken == null || _currentUserId == null) {
      print('API Service: fetchCurrentUser called without token or user ID. Returning null.');
      return null;
    }

    final userUrl = Uri.parse('$_baseUrl/auth/user/');
    print('API Service: Attempting to fetch current user info from $userUrl with token $_authToken');
    try {
      final userResponse = await http.get(userUrl, headers: _getHeaders());
      print('API Service: Fetch user response status: ${userResponse.statusCode}, body: ${userResponse.body}');

      if (userResponse.statusCode == 200) {
        return User.fromJson(jsonDecode(userResponse.body));
      } else if (userResponse.statusCode == 401) {
        print('API Service: Authentication failed (401) for basic user info. Token might be invalid or expired. Logging out.');
        await logout();
        return null;
      } else {
        print('API Service: Failed to fetch basic user info with status: ${userResponse.statusCode}, body: ${userResponse.body}');
        return null;
      }
    } catch (e) {
      print('API Service: Fetch Current User Error: $e');
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
      } else if (response.statusCode == 404) {
        print('API Service: Student profile not found for ID $_currentUserId. Returning null.');
        return null; // Explicitly return null if 404
      }
      print('API Service: Failed to fetch current student profile: ${response.statusCode}, body: ${response.body}');
      return null;
    } catch (e) {
      print('Fetch Current Student Profile Error: $e');
      return null;
    }
  }

  // Method to create a Student profile
  Future<Student?> createStudentProfile(int userId) async {
    await _ensureToken();
    if (_authToken == null) {
      print('API Service: createStudentProfile called without token. Returning null.');
      return null;
    }

    final url = Uri.parse('$_baseUrl/students/');
    // FIX: Changed 'user_id' to 'user' as per backend expectation
    final body = jsonEncode({
      'user': userId,
    });
    print('API Service: Creating student profile for user ID $userId with data: $body');
    try {
      final response = await http.post(url, headers: _getHeaders(), body: body);
      final responseData = jsonDecode(response.body);
      print('API Service: Create student profile response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        return Student.fromJson(responseData);
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for create student profile. Logging out.');
        await logout();
        return null;
      } else if (response.statusCode == 400 && responseData['user'] != null && responseData['user'].contains('student with this user already exists.')) {
        print('API Service: Student profile already exists for user ID $userId. Attempting to fetch it instead.');
        // If the student profile already exists, fetch it instead of failing
        return await fetchCurrentStudentProfile();
      }
      else {
        print('API Service: Failed to create student profile: ${response.statusCode}, body: ${response.body}');
        // Provide more specific error if available from backend
        if (responseData.containsKey('user')) {
          print('Backend Error for user field: ${responseData['user']}');
        }
        return null;
      }
    } catch (e) {
      print('API Service: Create Student Profile Error: $e');
      return null;
    }
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
        final dynamic responseData = jsonDecode(response.body);
        List<dynamic> data;

        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'];
        } else {
          print('API Service: Unexpected response structure for questions. Expected List or Map with "results".');
          return [];
        }
        return data.map((json) => Question.fromJson(json, lessonUuidFromContext: lessonUuid)).toList();
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

  Future<Map<String, dynamic>> addQuestion(Question question) async {
    await _ensureToken();
    if (_authToken == null) {
      return {'success': false, 'message': 'Authentication token not available.'};
    }

    final url = Uri.parse('$_baseUrl/questions/');
    final Map<String, dynamic> questionData = question.toJson();
    print('API Service: Adding question with data: ${jsonEncode(questionData)}');

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(questionData),
      );
      final responseData = jsonDecode(response.body);
      print('API Service: Add question response status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Question added successfully!', 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Failed to add question', 'errors': responseData};
      }
    } catch (e) {
      print('API Service: Error adding question: $e');
      return {'success': false, 'message': 'Network error during adding question: $e'};
    }
  }


  // --- QuizAttempt Endpoints ---
  Future<Map<String, dynamic>> uploadQuizAttempts(List<QuizAttempt> attempts) async {
    await _ensureToken();
    if (_authToken == null) {
      return {'success': false, 'message': 'Authentication token not available.'};
    }

    final url = Uri.parse('$_baseUrl/quiz-attempts/bulk_upload/');
    final List<Map<String, dynamic>> attemptsJson = attempts.map((a) {
      // The toJson() method of QuizAttempt now correctly includes 'student' as studentUuid
      return a.toJson();
    }).toList();

    print('API Service: Uploading quiz attempts: ${attemptsJson.length} attempts with data: ${jsonEncode(attemptsJson)}');

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
        return {'success': false, 'message': responseData['error'] ?? 'Bulk upload failed', 'errors': responseData};
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
    print('API Service: Fetching student progress for user ID: $studentUserId from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch student progress response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return StudentProgress.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for student progress. Token might be invalid or expired.');
        await logout();
        return null;
      } else if (response.statusCode == 404) {
        print('API Service: Student progress not found for user ID $_currentUserId. Returning null.');
        return null; // No progress found is a valid scenario
      }
      print('API Service: Failed to fetch student progress: ${response.statusCode}, body: ${response.body}');
      return null;
    } catch (e) {
      print('Fetch Student Progress Error: $e');
      return null;
    }
  }

  Future<StudentProgress?> updateStudentProgress(StudentProgress progress) async {
    await _ensureToken();
    if (_authToken == null) return null;

    final url = Uri.parse('$_baseUrl/student-progress/${progress.uuid}/'); // Use progress.uuid here
    print('API Service: Updating student progress for UUID: ${progress.uuid} with data: ${jsonEncode(progress.toJson())}');
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
      } else {
        print('API Service: Failed to update student progress: ${response.statusCode}, body: ${response.body}');
        return null;
      }
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
      'student': _currentUserId, // Send student's user ID
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

    final url = Uri.parse('$_baseUrl/wallets/$_currentUserId/'); // This assumes update by student_user_id
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

  // --- AI Service Calls ---
  Future<Map<String, dynamic>> getAiQuizFeedback(String questionText, String submittedAnswer, String correctAnswer, String questionType) async {
    await _ensureToken();
    final url = Uri.parse('$_baseUrl/ai/quiz-feedback/');
    final body = jsonEncode({
      'question_text': questionText,
      'submitted_answer': submittedAnswer,
      'correct_answer': correctAnswer,
      'question_type': questionType,
    });
    try {
      final response = await http.post(url, headers: _getHeaders(), body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'feedback_text': responseData['feedback_text'], 'score': responseData['score']};
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Authentication failed. Please log in again.'};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to get AI feedback'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during AI feedback request: $e'};
    }
  }

  Future<Map<String, dynamic>> getAiRecommendations(String studentIdCode) async {
    await _ensureToken();
    final url = Uri.parse('$_baseUrl/ai/recommendations/');
    final body = jsonEncode({'student_id_code': studentIdCode});
    try {
      final response = await http.post(url, headers: _getHeaders(), body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'recommendations': responseData['recommendations']};
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Authentication failed. Please log in again.'};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to get AI recommendations'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during AI recommendations request: $e'};
    }
  }
}
