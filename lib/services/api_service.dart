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
  static const String _baseUrl = kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';

  String? _authToken;
  int? _currentUserId; // Store current user ID

  // IMPORTANT FOR HACKATHON DEMO:
  // Hardcode a token here for judges to bypass login.
  // REPLACE 'YOUR_GENERATED_DJANGO_TOKEN_HERE' with the actual token you copied from Django admin.
  // Make sure there are no extra spaces or hidden characters.
  static const String _demoAuthToken = '7a22cba24bac92bde8419d8a1fdee152f921188c'; // <--- PASTE YOUR NEW TOKEN HERE

  // Private constructor for singleton pattern
  ApiService._internal();

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  // Public initialization method to be called once at app startup
  Future<void> init() async {
    print('API Service Initialized. Token from SharedPreferences: $_authToken');
    final prefs = await SharedPreferences.getInstance();

    // For hackathon, force the demo token for web
    if (kIsWeb) {
      _authToken = _demoAuthToken;
      // For demo, assume user ID 5 for ANA if using the hardcoded token
      // In a real app, this would come from a successful login response
      _currentUserId = 5; // Assuming ANA is user ID 5
      await prefs.setInt('currentUserId', _currentUserId!);
      print('API Service: FORCING hardcoded demo token for web: $_demoAuthToken, User ID: $_currentUserId');
    } else {
      // For mobile, try to load from SharedPreferences
      _authToken = prefs.getString('authToken');
      _currentUserId = prefs.getInt('currentUserId');
    }
    print('API Service: Final _authToken after init(): $_authToken, User ID: $_currentUserId');
  }

  // Ensure token is loaded before making an authenticated request
  Future<void> _ensureToken() async {
    if (_authToken == null) {
      await init(); // Re-initialize to load token if it's somehow null
      if (_authToken == null) {
        print('API Service: Warning: Auth token is still null after re-initialization.');
        // Potentially navigate to login screen or show error
      }
    }
  }

  Map<String, String> _getHeaders({bool includeAuth = true, bool isJson = true}) {
    final Map<String, String> headers = {};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  // New method to get current user ID
  Future<int?> getCurrentUserId() async {
    if (_currentUserId != null) {
      return _currentUserId;
    }
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('currentUserId');
    return _currentUserId;
  }

  // --- Authentication ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login/'); // Corrected endpoint
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'username': username, 'password': password}),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _authToken = responseData['token'];
        _currentUserId = responseData['user_id']; // Capture user ID on login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _authToken!);
        await prefs.setInt('currentUserId', _currentUserId!); // Store user ID
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during login. Please check connection.'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, String email, bool isStaff) async {
    final url = Uri.parse('$_baseUrl/auth/register/'); // Corrected endpoint
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'is_staff': isStaff,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        // Registration successful, now attempt to log in to get a token
        final loginResult = await login(username, password);
        if (loginResult['success']) {
          return {'success': true, 'message': 'Registration successful and logged in!'};
        } else {
          return {'success': true, 'message': 'Registration successful, but auto-login failed: ${loginResult['message']}'};
        }
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during registration. Please check connection.'};
    }
  }

  Future<void> logout() async {
    _authToken = null;
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('currentUserId');
  }

  // --- Student Profile ---
  Future<Student?> fetchCurrentStudentProfile() async {
    await _ensureToken(); // Ensure token is loaded
    if (_authToken == null) return null; // Cannot proceed without token

    final studentUrl = Uri.parse('$_baseUrl/students/');
    print('API Service: Fetching current student profile from $studentUrl');
    try {
      final response = await http.get(studentUrl, headers: _getHeaders());
      print('API Service: Fetch student profile response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> results = responseData['results'] ?? [];

        if (results.isNotEmpty) {
          // Assuming the first result is the current authenticated student's profile
          return Student.fromJson(results.first);
        } else {
          print('API Service: No student profile found for current user (results array is empty).');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for student profile. Token might be invalid or expired.');
        await logout(); // Clear invalid token and force re-login flow
        return null;
      }
      return null;
    } catch (e) {
      print('Fetch Student Profile Error: $e');
      return null;
    }
  }

  // --- Lessons ---
  Future<List<Lesson>> fetchLessons() async {
    await _ensureToken(); // Ensure token is loaded
    if (_authToken == null) return []; // Cannot proceed without token

    final url = Uri.parse('$_baseUrl/lessons/');
    print('API Service: Fetching lessons from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch lessons response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> results = responseData['results'] ?? [];
        return results.map((json) => Lesson.fromJson(json)).toList();
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
    print('API Service: Creating lesson: ${lesson.title}');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(lesson.toJson()),
      );
      print('API Service: Create lesson response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        return Lesson.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to create lesson: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create Lesson Error: $e');
      return null;
    }
  }

  // --- Questions ---
  Future<List<Question>> fetchQuestionsForLesson(String lessonUuid) async {
    await _ensureToken();
    if (_authToken == null) return [];

    final url = Uri.parse('$_baseUrl/questions/?lesson_uuid=$lessonUuid');
    print('API Service: Fetching questions for lesson UUID: $lessonUuid from $url');
    try {
      final response = await http.get(url, headers: _getHeaders());
      print('API Service: Fetch questions response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> results = responseData['results'] ?? [];
        return results.map((json) => Question.fromJson(json)).toList();
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
    print('API Service: Creating question: ${question.questionText}');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(question.toJson()),
      );
      print('API Service: Create question response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        return Question.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to create question: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create Question Error: $e');
      return null;
    }
  }

  // --- Quiz Attempts Sync ---
  Future<Map<String, dynamic>> uploadQuizAttempts(List<QuizAttempt> attempts) async {
    await _ensureToken();
    if (_authToken == null) return {'success': false, 'message': 'Authentication token missing. Please log in.'};

    final url = Uri.parse('$_baseUrl/quiz-attempts/bulk_upload/');
    print('API Service: Uploading ${attempts.length} quiz attempts to $url');
    try {
      final List<Map<String, dynamic>> attemptsJson = attempts.map((e) => e.toJson()).toList();
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(attemptsJson),
      );
      print('API Service: Upload quiz attempts response status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'message': 'Quiz attempts uploaded successfully.', 'data': responseData};
      } else if (response.statusCode == 401) {
        print('API Service: Authentication failed (401) for quiz attempts upload. Token might be invalid or expired.');
        await logout();
        return {'success': false, 'message': 'Authentication failed. Please log in again.'};
      } else {
        // If Django returns HTML for 404, jsonDecode will fail.
        // We'll try to parse JSON, but fallback to raw body if it's not JSON.
        String errorMessage = 'Failed to upload quiz attempts.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server responded with non-JSON error: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...';
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Upload Quiz Attempts Error: $e');
      return {'success': false, 'message': 'Network error during quiz attempts upload: $e'};
    }
  }

  // --- Student Progress ---
  Future<StudentProgress?> fetchStudentProgress(int studentUserId) async {
    await _ensureToken();
    if (_authToken == null) return null;

    final url = Uri.parse('$_baseUrl/student_progress/$studentUserId/'); // Assuming endpoint by student user ID
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

    final url = Uri.parse('$_baseUrl/student_progress/${progress.studentUserId}/'); // Assuming endpoint by student user ID
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
}
