// learnflow_ai/flutter_app/lib/main.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/screens/home_screen.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

// Conditional import for sqflite_common_ffi for web/desktop
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for sqflite_common_ffi and sqflite_common_ffi_web
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as sqflite_ffi_web;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for the correct platform
  if (kIsWeb) {
    print('main(): Running on Web. Initializing sqflite_common_ffi_web...');
    databaseFactory = sqflite_ffi_web.databaseFactoryFfiWeb;
    print('main(): sqflite_common_ffi_web initialized.');
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    print('main(): Running on Desktop. Initializing sqflite_common_ffi...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('main(): sqflite_common_ffi initialized.');
  } else {
    print('main(): Running on Mobile (Android/iOS). Using default sqflite.');
    // Default sqflite for mobile platforms
  }

  // Initialize ApiService and wait for its async initialization to complete
  print('main(): Initializing ApiService...');
  final apiService = ApiService(); // Create instance
  await apiService.init(); // Await the async initialization
  print('main(): ApiService initialized.');


  // Initialize DatabaseService
  print('main(): Initializing DatabaseService...');
  final databaseService = DatabaseService.instance;
  // Ensure the database is initialized (tables created/opened) before runApp
  await databaseService.database; // Accessing the getter ensures initialization
  print('main(): DatabaseService initialized successfully.');


  print('main(): runApp called.');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // We are directly navigating to HomeScreen for hackathon demo purposes
  // In a real app, you would check authentication status here.
  @override
  void initState() {
    super.initState();
    // Bypassing authentication as we are directly going to HomeScreen
    print('MyApp initState: Bypassing authentication and directly navigating to HomeScreen.');
  }

  @override
  Widget build(BuildContext context) {
    print('MyApp build: Directly rendering HomeScreen.');
    return MaterialApp(
      title: 'LearnFlow AI',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
      ),
      // Directly set home to HomeScreen to bypass authentication for hackathon
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// SplashScreen is no longer used as we directly go to HomeScreen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('SplashScreen build: This should not be seen if direct navigation is working.');
    return const Scaffold(
      backgroundColor: Colors.red,
      body: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Loading LearnFlow AI...',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
