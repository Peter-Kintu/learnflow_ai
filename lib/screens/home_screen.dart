// learnflow_ai/flutter_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/screens/lessons_screen.dart';
import 'package:learnflow_ai/screens/teacher_dashboard_screen.dart';
import 'package:learnflow_ai/screens/sync_status_screen.dart';
import 'package:learnflow_ai/screens/wallet_screen.dart'; // Import WalletScreen
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  User? _currentUser; // This is directly the User object
  bool _isLoading = true;

  // Animation controller for the icon and text
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slightly longer duration
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack, // More dynamic curve
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn, // Smooth fade in
      ),
    );

    _animationController.forward(); // Start the animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _apiService.fetchCurrentUser(); // This returns a User object
      setState(() {
        _currentUser = user; // _currentUser is directly assigned the User object
        _isLoading = false;
      });
      if (user == null) {
        print("No current user found or token invalid. Please log in.");
      }
    } catch (e) {
      print('Error fetching current user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to launch the web-based teacher dashboard
  Future<void> _launchTeacherDashboardWeb() async {
    // IMPORTANT: Use your live Render.com URL for the Django backend here.
    // The path is /teacher-dashboard/ as defined in your Django urls.py
    final Uri url = Uri.parse('https://africana-ntgr.onrender.com/teacher-dashboard/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('LearnFlow AI'),
          backgroundColor: Colors.deepPurple.shade900,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnFlow AI'),
        backgroundColor: Colors.deepPurple.shade900, // Even darker purple for app bar
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          // Wallet Button in AppBar
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 30), // Larger, rounded icon
            color: Colors.amber.shade400, // Richer gold for the icon
            tooltip: 'My Wallet (LFT)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 30), // Larger, rounded icon
            tooltip: 'Logout',
            onPressed: () async {
              await _apiService.logout();
              print('Logged out.');
              // No need to setState _currentUser = null here, as main.dart always goes to HomeScreen
              // For a real app, you'd navigate to AuthScreen here.
            },
          ),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0), // Increased vertical padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Animated icon for a more dynamic feel
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(35), // Even larger padding for icon
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
                      child: const Icon(
                        Icons.lightbulb_outline_rounded, // Rounded icon
                        size: 90, // Larger icon
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50), // Increased spacing

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Welcome, ${_currentUser?.username ?? 'Learner'}!', // CORRECTED: Removed .user
                    style: TextStyle(
                      fontSize: size.width * 0.08, // Even larger font for welcome
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 15.0, // More blur for shadow
                          color: Colors.black87,
                          offset: Offset(3.0, 3.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20), // Increased spacing

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your personalized learning journey awaits!',
                    style: TextStyle(
                      fontSize: size.width * 0.045, // Slightly larger
                      color: Colors.white, // Pure white
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300, // Lighter weight
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 70), // Even more spacing

                _buildHomeButton(
                  context,
                  'Explore Lessons',
                  Icons.menu_book_rounded,
                  const LessonsScreen(),
                  Colors.white,
                  Colors.deepPurple.shade800, // Darker purple for text
                ),
                const SizedBox(height: 25), // Increased spacing

                _buildHomeButton(
                  context,
                  'View Sync Status',
                  Icons.sync_alt_rounded,
                  const SyncStatusScreen(),
                  Colors.tealAccent.shade700, // Even brighter teal
                  Colors.teal.shade900, // Darker teal for text
                ),
                const SizedBox(height: 25), // Increased spacing

                // New button to launch the web-based Teacher Dashboard
                _buildHomeButton(
                  context,
                  'View Web Dashboard',
                  Icons.dashboard_rounded,
                  // This button will launch an external URL, not navigate to a Flutter screen
                  // We'll use a dummy screen for type safety, but the onPressed will override it.
                  Container(),
                  Colors.orange.shade700, // Vibrant orange
                  Colors.white,
                  onPressed: _launchTeacherDashboardWeb, // Call the new function
                ),
                const SizedBox(height: 50), // Increased spacing

                _buildHomeButton(
                  context,
                  'Teacher Dashboard (Flutter)',
                  Icons.school_rounded,
                  const TeacherDashboardScreen(),
                  Colors.indigo.shade800, // Even darker indigo
                  Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modified _buildHomeButton to accept an optional onPressed callback
  Widget _buildHomeButton(BuildContext context, String label, IconData icon, Widget screen, Color bgColor, Color fgColor, {VoidCallback? onPressed}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.85, // Even wider buttons
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () { // Use provided onPressed or default navigation
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        icon: Icon(icon, size: 35), // Even larger icon
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 22), // Even larger padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)), // Even more rounded
          textStyle: TextStyle(
            fontSize: size.width * 0.05, // Even larger text
            fontWeight: FontWeight.bold,
          ),
          elevation: 12, // More shadow
          shadowColor: Colors.black.withOpacity(0.6),
        ),
      ),
    );
  }
}
