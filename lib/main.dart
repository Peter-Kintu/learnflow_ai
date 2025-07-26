// learnflow_ai/flutter_app/lib/main.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/screens/home_screen.dart';
import 'package:learnflow_ai/screens/auth_screen.dart'; // Import AuthScreen
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';

// Conditional import for sqflite_common_ffi for web/desktop
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for sqflite_common_ffi and sqflite_common_ffi_web
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as sqflite_ffi_web;


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async operations before runApp

  // Initialize sqflite for the correct platform
  if (kIsWeb) {
    print('main(): Running on Web. Initializing sqflite_common_ffi_web...');
    databaseFactory = sqflite_ffi_web.databaseFactoryFfiWeb;
    print('main(): sqflite_common_ffi_web initialized.');
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    print('main(): Running on Desktop. Initializing sqflite_common_ffi...');
    sqfliteFfiInit(); // Initialize FFI for desktop
    databaseFactory = databaseFactoryFfi;
    print('main(): sqflite_common_ffi initialized.');
  } else {
    print('main(): Running on Mobile (Android/iOS). Using default sqflite.');
    // Default sqflite for mobile platforms
  }

  // ApiService is now initialized in its constructor, which loads the token.
  final ApiService apiService = ApiService(); // Create instance

  // Initialize DatabaseService
  print('main(): Initializing DatabaseService...');
  final databaseService = DatabaseService.instance;
  // Ensure the database is initialized (tables created/opened) before runApp
  await databaseService.database; // Accessing the getter ensures initialization
  print('main(): DatabaseService initialized successfully.');

  // Check if a user is already logged in (has a valid token)
  // This will try to load the token from shared preferences.
  // If no token, _authToken will be null, and fetchCurrentUser will return null.
  final currentUser = await apiService.fetchCurrentUser();
  final bool isLoggedIn = currentUser != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; // Pass the login status to MyApp

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    print('MyApp build: isLoggedIn: $isLoggedIn');
    return MaterialApp(
      title: 'LearnFlow AI',
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData(
        // Define a primary color swatch for consistent theming
        primarySwatch: Colors.deepPurple, // Sets the primary color and generates shades
        primaryColor: Colors.deepPurple.shade800, // Explicit primary color
        hintColor: Colors.purpleAccent.shade400, // Accent color for hints/focus
        scaffoldBackgroundColor: Colors.white, // Default background for scaffolds
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade900, // Consistent app bar color
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0, // No shadow for app bars
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          buttonColor: Colors.deepPurpleAccent.shade700,
          textTheme: ButtonTextTheme.primary,
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.deepPurple.shade50.withOpacity(0.8),
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
          labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
        // Add more theme properties as needed for consistency
      ),
      // Conditionally navigate based on login status
      home: isLoggedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}
