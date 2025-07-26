// learnflow_ai/flutter_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/screens/lessons_screen.dart';
import 'package:learnflow_ai/screens/teacher_dashboard_screen.dart';
import 'package:learnflow_ai/screens/sync_status_screen.dart';
import 'package:learnflow_ai/screens/wallet_screen.dart'; // Import WalletScreen
import 'package:url_launcher/url_launcher.dart'; // Keep this import for wallet screen potentially
import 'package:learnflow_ai/screens/auth_screen.dart'; // Import AuthScreen for logout navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
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
      leading: Icon(icon, color: Colors.deepPurple.shade700, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple.shade900,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      hoverColor: Colors.deepPurple.shade600.withOpacity(0.4), // Subtle hover effect
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
        backgroundColor: Colors.deepPurple.shade700,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade700,
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
                        ),
                      ),
                  ],
                ),
              ),
              _buildDrawerItem(
                'Lessons',
                Icons.book_rounded,
                    () => Navigator.pop(context), // Close drawer
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
                'Sync Status',
                Icons.sync_rounded,
                    () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncStatusScreen()));
                },
              ),
              if (_currentUser?.isStaff == true)
                _buildDrawerItem(
                  'Teacher Dashboard',
                  Icons.dashboard_rounded,
                      () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()));
                  },
                ),
              const Divider(height: 20, thickness: 1, indent: 20, endIndent: 20, color: Colors.deepPurple),
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
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      Icons.school_rounded,
                      size: size.width * 0.3,
                      color: Colors.deepPurple.shade700,
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
                        color: Colors.deepPurple.shade900,
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
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),
                  // Buttons are now handled by the drawer for a cleaner home screen
                  // This space can be used for other widgets or left as padding
                  SizedBox(
                    width: size.width * 0.75,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LessonsScreen()),
                        );
                      },
                      icon: const Icon(Icons.book_rounded, size: 28),
                      label: const Text('Start Learning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
                        foregroundColor: Colors.white,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
