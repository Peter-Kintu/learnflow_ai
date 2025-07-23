// learnflow_ai/flutter_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/screens/lessons_screen.dart';
import 'package:learnflow_ai/screens/teacher_dashboard_screen.dart';
import 'package:learnflow_ai/screens/sync_status_screen.dart';
import 'package:learnflow_ai/screens/wallet_screen.dart'; // Import WalletScreen
import 'package:url_launcher/url_launcher.dart'; // Keep this import for wallet screen potentially

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
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
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
      final user = await _apiService.fetchCurrentUser();
      setState(() {
        _currentUser = user;
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
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        // ADDED: Leading icon to open the Drawer
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, size: 30), // Hamburger icon
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          // Wallet Button in AppBar
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 28),
            color: Colors.amber.shade400,
            tooltip: 'My Wallet (LFT)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 28),
            tooltip: 'Logout',
            onPressed: () async {
              await _apiService.logout();
              print('Logged out.');
              // For a real app, you'd navigate to AuthScreen here.
            },
          ),
        ],
      ),
      // ADDED: The Drawer widget for the sliding menu
      drawer: Drawer(
        backgroundColor: Colors.deepPurple.shade800, // Darker background for the drawer
        child: ListView(
          padding: EdgeInsets.zero, // Remove default padding
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade900, Colors.indigo.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hello, ${_currentUser?.username ?? 'Learner'}!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your Learning Hub',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Moved buttons into the Drawer
            _buildDrawerButton(
              context,
              'Explore Lessons',
              Icons.menu_book_rounded,
              const LessonsScreen(),
            ),
            _buildDrawerButton(
              context,
              'View Sync Status',
              Icons.sync_alt_rounded,
              const SyncStatusScreen(),
            ),
            _buildDrawerButton(
              context,
              'Teacher Dashboard',
              Icons.school_rounded,
              const TeacherDashboardScreen(),
            ),
            const Divider(color: Colors.white54), // Divider for visual separation
            _buildDrawerButton(
              context,
              'My Wallet (LFT)',
              Icons.account_balance_wallet_rounded,
              const WalletScreen(),
            ),
            _buildDrawerButton(
              context,
              'Logout',
              Icons.logout_rounded,
              null, // No screen, handled by onPressed
              onPressed: () async {
                await _apiService.logout();
                Navigator.pop(context); // Close drawer
                // For a real app, you'd navigate to AuthScreen here.
                // For this demo, it just clears token and stays on home.
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade700, Colors.purple.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Animated icon
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Welcome, ${_currentUser?.username ?? 'Learner'}!',
                    style: TextStyle(
                      fontSize: size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black54,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your personalized learning journey awaits!',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),

                // Removed buttons from here, they are now in the Drawer
                // You can add other content here if desired, or leave it cleaner
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for consistent button styling within the Drawer
  Widget _buildDrawerButton(BuildContext context, String label, IconData icon, Widget? screen, {VoidCallback? onPressed}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 28),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onPressed ?? () {
        // Close the drawer before navigating
        Navigator.pop(context);
        if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
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
          animationDuration: const Duration(milliseconds: 200),
          overlayColor: fgColor.withOpacity(0.1),
        ),
      ),
    );
  }
}
