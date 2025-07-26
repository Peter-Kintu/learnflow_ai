// learnflow_ai/flutter_app/lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _studentIdCodeController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print('AuthScreen: Attempting login...');
    final username = _usernameController.text;
    final password = _passwordController.text;

    final result = await _apiService.loginUser(username, password);

    if (result['success']) {
      print('AuthScreen: Login successful.');
      _navigateToHome();
    } else {
      print('AuthScreen: Login failed - ${result['message']}');
      setState(() {
        _errorMessage = result['message'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print('AuthScreen: Attempting registration...');
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final studentIdCode = _studentIdCodeController.text.isNotEmpty ? _studentIdCodeController.text : null;

    // Basic validation for email during registration
    if (email.isEmpty && !_isLogin) { // Only require email if registering
      setState(() {
        _errorMessage = 'Email is required for registration.';
        _isLoading = false;
      });
      return;
    }

    final result = await _apiService.registerUser(username, email, password, studentIdCode: studentIdCode);

    if (result['success']) {
      print('AuthScreen: Registration successful.');
      // After successful registration, automatically log in the user and navigate to home
      // Or, if you prefer, switch to login form and let them log in manually:
      // setState(() { _isLogin = true; });
      _navigateToHome();
    } else {
      print('AuthScreen: Registration failed - ${result['message']}');
      setState(() {
        _errorMessage = result['message'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('AuthScreen build: Rendering. IsLogin: $_isLogin');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700], // Deeper, richer gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(36.0), // Even more padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Animated icon for a more dynamic feel
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000), // Longer animation
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.7 + (0.3 * value), // Scale from 70% to 100%
                      child: Opacity(
                        opacity: value, // Fade in
                        child: Container(
                          padding: const EdgeInsets.all(30), // Larger padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25), // Slightly more opaque
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4), // Stronger shadow
                                blurRadius: 20, // More blur
                                offset: const Offset(0, 10), // More offset
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded, size: 110, color: Colors.white), // Larger, rounded icon
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50), // Increased spacing

                Text(
                  _isLogin ? 'Welcome Back, Learner!' : 'Embark on Your Journey!',
                  style: const TextStyle(
                    fontSize: 38, // Even larger font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 15.0, color: Colors.black87, offset: Offset(3.0, 3.0)), // More prominent shadow
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30), // Increased spacing

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0), // Increased padding
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent, // Consistent error color
                        fontSize: 17, // Slightly larger
                        fontWeight: FontWeight.w700, // Bolder
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Text fields with enhanced styling
                _buildAuthTextField(_usernameController, 'Username', Icons.person_rounded), // Rounded icon
                const SizedBox(height: 25), // Increased spacing

                if (!_isLogin) ...[
                  _buildAuthTextField(_emailController, 'Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress), // Made email required for registration
                  const SizedBox(height: 25),
                  _buildAuthTextField(_studentIdCodeController, 'Student ID Code (Optional)', Icons.badge_rounded, hintText: 'Provided by your teacher'), // Rounded icon
                  const SizedBox(height: 25),
                ],
                _buildAuthTextField(_passwordController, 'Password', Icons.lock_rounded, obscureText: true), // Rounded icon
                const SizedBox(height: 40), // Increased spacing

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _isLogin ? _login : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent.shade700, // More vibrant purple
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20), // Even larger button
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
                          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // Larger, bolder text
                          elevation: 12, // More shadow
                          shadowColor: Colors.deepPurple.shade900.withOpacity(0.7),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Register'),
                      ),
                const SizedBox(height: 30), // Increased spacing

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null; // Clear error message on toggle
                    });
                    print('AuthScreen: Toggled to _isLogin=$_isLogin');
                  },
                  child: Text(
                    _isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Login',
                    style: const TextStyle(
                      color: Colors.white, // Pure white for better visibility
                      fontSize: 17, // Slightly larger
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      decorationThickness: 1.5, // Thicker underline
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

  // Helper method for consistent text field styling
  Widget _buildAuthTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType keyboardType = TextInputType.text, String? hintText}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 17), // Slightly larger text
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600), // Bolder, darker label
        hintStyle: TextStyle(color: Colors.grey.shade600), // Darker hint text
        filled: true,
        fillColor: Colors.white.withOpacity(0.98), // Almost opaque white
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), // Even more rounded
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 1.5), // Thicker, clearer border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.deepPurple.shade800, width: 3), // Even thicker focused border
        ),
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade500), // Slightly brighter icon
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15), // Adjust padding
      ),
    );
  }
}
