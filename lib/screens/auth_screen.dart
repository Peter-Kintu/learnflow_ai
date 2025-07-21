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

    final result = await _apiService.registerUser(username, email, password, studentIdCode: studentIdCode);

    if (result['success']) {
      print('AuthScreen: Registration successful.');
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
      backgroundColor: Colors.purple, // ANOTHER VERY OBVIOUS COLOR
      appBar: AppBar(
        title: Text(_isLogin ? 'Login to LearnFlow AI' : 'Register for LearnFlow AI'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SizedBox.expand( // Force it to take full screen
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Temporarily removed Image.asset to rule out asset loading issues
                const Icon(Icons.school, size: 120, color: Colors.white), // Placeholder icon
                const SizedBox(height: 30),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Join LearnFlow AI',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Changed text color for visibility
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.yellow, fontSize: 16), // Changed error color
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    filled: true, // Make sure background is filled
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isLogin)
                  Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email (Optional)',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _studentIdCodeController,
                        decoration: InputDecoration(
                          labelText: 'Student ID Code (Optional)',
                          hintText: 'Provided by your teacher',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _isLogin ? _login : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Register'),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    });
                    print('AuthScreen: Toggled to _isLogin=$_isLogin');
                  },
                  child: Text(
                    _isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Login',
                    style: const TextStyle(color: Colors.white), // Changed text color for visibility
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
