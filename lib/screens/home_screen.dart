// learnflow_ai/flutter_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/screens/lessons_screen.dart';
import 'package:learnflow_ai/screens/teacher_dashboard_screen.dart'; // Ensure this import is correct
import 'package:learnflow_ai/screens/sync_status_screen.dart';
import 'package:learnflow_ai/screens/wallet_screen.dart'; // Import WalletScreen
import 'package:url_launcher/url_launcher.dart'; // Keep this import for wallet screen potentially
import 'package:learnflow_ai/screens/auth_screen.dart'; // Import AuthScreen for logout navigation
import 'package:learnflow_ai/screens/tutor_ai_screen.dart'; // Make sure this path is correct
import 'package:learnflow_ai/screens/add_lesson_screen.dart'; // Import AddLessonScreen
import 'package:learnflow_ai/screens/add_question_screen.dart'; // Import AddQuestionScreen


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;
  User? _currentUser; // This is directly the User object
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controller for the icon and text
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _apiService.fetchCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        _animationController.forward(); // Start animation on successful load
        // Also update the local database with the latest user info
        await _databaseService.insertUser(user);
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data. Please log in again.';
          _isLoading = false;
        });
        // If user is null, navigate back to AuthScreen
        _navigateToAuth();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user data: $e';
        _isLoading = false;
      });
      _navigateToAuth(); // Navigate to auth on error
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    _navigateToAuth(); // Navigate to AuthScreen after logout
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      // Updated colors for consistency with the new gradient theme
      leading: Icon(icon, color: Colors.white, size: 28), // White icons for contrast on dark drawer
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white, // White text for contrast
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      hoverColor: Colors.white.withOpacity(0.2), // Subtle hover effect
      tileColor: Colors.transparent, // Ensure no default background
    );
  }

  // The _buildHomeButton is no longer used in this version of HomeScreen
  // but kept here in case it's used elsewhere or for future reference.
  Widget _buildHomeButton(
      BuildContext context,
      String label,
      IconData icon,
      Widget screen,
      Color bgColor,
      Color fgColor,
      ) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.75,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        icon: Icon(icon, size: 28),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textStyle: TextStyle(
            fontSize: size.width * 0.042,
            fontWeight: FontWeight.w600,
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnFlow AI'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade700, // AppBar color can be adjusted if needed for consistency
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCurrentUser,
            tooltip: 'Refresh User Data',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          // Drawer background gradient - MATCHING AuthScreen/Home Body
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // DrawerHeader with flexible content
              // Removed fixed height constraint, allowing it to size based on content
              // Added a minimum height using SizedBox for visual consistency
              SizedBox(
                height: 180, // Set a fixed height for the DrawerHeader area
                child: DrawerHeader(
                  margin: EdgeInsets.zero, // Remove default margin
                  padding: const EdgeInsets.all(16.0), // Add custom padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end, // Align content to the bottom
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          _currentUser?.username ?? 'Guest User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow for long usernames
                        ),
                      ),
                      if (_currentUser?.isStaff == true)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Teacher/Admin',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis, // Prevent overflow
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Main navigation items, consistent with previous design
              _buildDrawerItem(
                'Lessons',
                Icons.book_rounded,
                    () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LessonsScreen()));
                },
              ),
              _buildDrawerItem(
                'My Wallet',
                Icons.account_balance_wallet_rounded,
                    () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
                },
              ),
              _buildDrawerItem(
                  'AI TutorBot',
               Icons.smart_toy_rounded,
               () {
                Navigator.pop(context); // Close drawer
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const TutorAIScreen()));
               },
            ),

              _buildDrawerItem(
                'Sync Status',
                Icons.sync_rounded,
                    () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncStatusScreen()));
                },
              ),
             // if (_currentUser?.isStaff == true) ...[
                _buildDrawerItem(
                  'Teacher Dashboard',
                  Icons.dashboard_rounded,
                      () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()));
                  },
                ),
                _buildDrawerItem(
                  'Add Lesson',
                  Icons.add_box,
                      () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddLessonScreen()));
                  },
                ),
                _buildDrawerItem(
                  'Add Question',
                  Icons.question_mark,
                      () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddQuestionScreen()));
                  },
                ),
              //],
              Divider(height: 20, thickness: 1, indent: 20, endIndent: 20, color: Colors.white.withOpacity(0.3)),
              _buildDrawerItem(
                'Logout',
                Icons.logout_rounded,
                _handleLogout,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.red.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToAuth,
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          // Background gradient - MATCHING AuthScreen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Main content: Wrapped in SingleChildScrollView to prevent overflow
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      Icons.school_rounded,
                      size: size.width * 0.3,
                      color: Colors.white, // Changed to white for better contrast on dark background
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Welcome, ${_currentUser?.username ?? 'User'}!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to white
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Your personalized learning journey starts here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width * 0.038,
                        color: Colors.white70, // Changed to white70 for contrast
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),
                  // Removed the ElevatedButton for "Start Learning" from here.
                  // All navigation is now exclusively through the drawer.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
