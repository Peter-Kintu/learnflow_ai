// learnflow_ai/flutter_app/lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart'; // Import DatabaseService
import 'package:learnflow_ai/models/user.dart'; // Import the User model
import 'package:learnflow_ai/models/student.dart'; // Import the Student model
import 'package:learnflow_ai/screens/home_screen.dart'; // Navigate to HomeScreen after auth

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance; // Initialize DatabaseService
  final _formKey = GlobalKey<FormState>(); // Use a Form key for validation
  bool _isLogin = true;
  String _username = '';
  String _email = '';
  String _password = '';
  String? _studentIdCode;
  String? _gender; // Added for registration form
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check if already logged in on init
  }

  // Method to check if a user is already logged in based on stored token
  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });
    final userId = await _apiService.getCurrentUserId();
    if (userId != null) {
      // If a user ID is found locally, attempt to fetch user/student profile
      final user = await _apiService.fetchCurrentUser();
      if (user != null) {
        // If user data is successfully fetched, navigate to HomeScreen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // If user ID exists but fetching user data failed (e.g., token expired/invalid),
        // clear token and show login screen.
        await _apiService.logout();
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Unified method for both login and registration submission
  Future<void> _submitForm() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Save the form fields

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error messages
    });

    Map<String, dynamic> result;
    if (_isLogin) {
      print('AuthScreen: Attempting login...');
      result = await _apiService.loginUser(_username, _password);
      if (result['success']) {
        print('AuthScreen: Login successful.');
        // After successful login, ensure a student profile exists for this user
        final int? userId = await _apiService.getCurrentUserId();
        if (userId != null) {
          // This call to createStudentProfile will now handle the "already exists" case
          // by fetching the existing student profile.
          Student? student = await _apiService.createStudentProfile(userId);

          // If student is still null here, it means creation failed and wasn't an "already exists" case
          // or fetching the existing one failed.
          if (student == null) {
            _errorMessage = 'Failed to load or create student profile after login. Please try again or contact support.';
            print('AuthScreen: ERROR: $_errorMessage');
            await _apiService.logout(); // Logout if student profile cannot be established
            if (mounted) {
              setState(() { _isLoading = false; });
            }
            return;
          }
          print('AuthScreen: Student profile found/created for user ID $userId: ${student.toJson()}.');

          // Save user and student to local database after successful login and student profile check/creation
          final user = User(id: userId, username: _username, email: _email, isStaff: false); // isStaff will be updated by full user fetch
          await _databaseService.insertUser(user);
          await _databaseService.insertStudent(student); // Save the student with its UUID
        }

        // Navigate to HomeScreen after successful login and student profile check/creation
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        print('AuthScreen: Login failed. Message: ${result['message']}');
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } else { // Registration flow
      print('AuthScreen: Attempting registration...');
      // Basic validation for email during registration
      if (_email.isEmpty) {
        setState(() {
          _errorMessage = 'Email is required for registration.';
          _isLoading = false;
        });
        return;
      }

      result = await _apiService.registerUser(
        _username,
        _password,
        email: _email, // Now explicitly named
        studentIdCode: _studentIdCode,
        gender: _gender,
      );
      if (result['success']) {
        print('AuthScreen: Registration successful.');
        final int userId = result['user_id'];

        // Create student profile immediately after user registration
        // This call will also handle the "already exists" case gracefully
        Student? student = await _apiService.createStudentProfile(userId);

        if (student != null) {
          print('AuthScreen: Student profile created for user ID $userId: ${student.toJson()}.');
          // Save user and student to local database
          final user = User(id: userId, username: _username, email: _email, isStaff: false); // isStaff will be updated by full user fetch
          await _databaseService.insertUser(user);
          await _databaseService.insertStudent(student); // Save the student with its UUID
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Registration successful, but failed to create student profile.';
            _isLoading = false;
          });
          print('AuthScreen: Failed to create student profile after registration.');
        }
      } else {
        print('AuthScreen: Registration failed. Message: ${result['message']}');
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Helper method for consistent text field styling
  InputDecoration _inputDecoration(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white.withOpacity(0.98),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.deepPurple.shade800, width: 3),
      ),
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade500),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('AuthScreen build: Rendering. IsLogin: $_isLogin');
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Animated icon
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.7 + (0.3 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded, size: 110, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),

                Text(
                  _isLogin ? 'Welcome Back, Learner!' : 'Embark on Your Journey!',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 15.0, color: Colors.black87, offset: Offset(3.0, 3.0)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Form fields
                Form( // Wrap text fields in a Form widget to use GlobalKey
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: _inputDecoration(
                          'Username',
                          Icons.person_rounded,
                          hintText: 'Enter your username',
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid username.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _username = value!;
                        },
                      ),
                      const SizedBox(height: 25),

                      if (!_isLogin) ...[
                        TextFormField(
                          decoration: _inputDecoration(
                            'Email',
                            Icons.email_rounded,
                            hintText: 'Enter your email address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null || !value.contains('@') || value.trim().isEmpty) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _email = value!;
                          },
                        ),
                        const SizedBox(height: 25),
                        TextFormField(
                          decoration: _inputDecoration(
                            'Student ID Code (Optional)',
                            Icons.badge_rounded,
                            hintText: 'Provided by your teacher',
                          ),
                          keyboardType: TextInputType.text,
                          onSaved: (value) {
                            _studentIdCode = value?.trim();
                          },
                        ),
                        const SizedBox(height: 25),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(
                            'Gender (Optional)',
                            Icons.wc,
                          ),
                          value: _gender,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Select Gender')),
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                            DropdownMenuItem(value: 'O', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                          onSaved: (value) {
                            _gender = value;
                          },
                        ),
                        const SizedBox(height: 25),
                      ],
                      TextFormField(
                        decoration: _inputDecoration(
                          'Password',
                          Icons.lock_rounded,
                          hintText: 'Enter your password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          elevation: 12,
                          shadowColor: Colors.deepPurple.shade900.withOpacity(0.7),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Register'),
                      ),
                const SizedBox(height: 30),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null; // Clear error message on toggle
                      // Clear saved values when switching modes to ensure form state is fresh
                      _username = '';
                      _email = '';
                      _password = '';
                      _studentIdCode = null;
                      _gender = null;
                      _formKey.currentState?.reset(); // Reset form state
                    });
                    print('AuthScreen: Toggled to _isLogin=$_isLogin');
                  },
                  child: Text(
                    _isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Login',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      decorationThickness: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
