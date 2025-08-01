// learnflow_ai/flutter_app/lib/models/student.dart

import 'package:learnflow_ai/models/user.dart'; // Import the User model

class Student {
  final String uuid; // Made non-nullable as it's a primary key
  final int userId; // Foreign key to User model, made non-nullable
  final User? user; // Nested User object (optional for display)
  final String? studentIdCode;
  final String? gradeLevel;
  final String? className;
  final DateTime dateRegistered;
  final DateTime? lastDeviceSync;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? schoolName;
  final String? walletAddress; // New field for blockchain wallet address

  Student({
    required this.uuid, // Made required
    required this.userId, // Made required
    this.user,
    this.studentIdCode,
    this.gradeLevel,
    this.className,
    required this.dateRegistered,
    this.lastDeviceSync,
    this.gender,
    this.dateOfBirth,
    this.schoolName,
    this.walletAddress,
  });

  // Convert a Student object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid, // Include UUID
      'user_id': userId,
      'student_id_code': studentIdCode,
      'grade_level': gradeLevel,
      'class_name': className,
      'date_registered': dateRegistered.toIso8601String(),
      'last_device_sync': lastDeviceSync?.toIso8601String(),
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'school_name': schoolName,
      'wallet_address': walletAddress,
    };
  }

  // Convert a Map object into a Student object (from SQLite)
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      uuid: map['uuid'] as String, // Retrieve UUID (non-nullable)
      userId: map['user_id'] as int, // Retrieve userId (non-nullable)
      // User object is not stored directly in student table, so it's null here
      user: null,
      studentIdCode: map['student_id_code'] as String?,
      gradeLevel: map['grade_level'] as String?,
      className: map['class_name'] as String?,
      dateRegistered: DateTime.parse(map['date_registered'] as String),
      lastDeviceSync: map['last_device_sync'] != null ? DateTime.parse(map['last_device_sync'] as String) : null,
      gender: map['gender'] as String?,
      dateOfBirth: map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth'] as String) : null,
      schoolName: map['school_name'] as String?,
      walletAddress: map['wallet_address'] as String?,
    );
  }

  // Convert a Student object into a JSON object (for API)
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid, // Include UUID
      'user': userId, // Send user_id for API as 'user' (integer)
      // 'user' is read-only from API, not sent in POST/PUT
      'student_id_code': studentIdCode,
      'grade_level': gradeLevel,
      'class_name': className,
      'date_registered': dateRegistered.toIso8601String(),
      'last_device_sync': lastDeviceSync?.toIso8601String(),
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'school_name': schoolName,
      'wallet_address': walletAddress,
    };
  }

  // Factory constructor to create a Student from JSON (from API)
  factory Student.fromJson(Map<String, dynamic> json) {
    User? parsedUser;
    int extractedUserId;

    // Handle the 'user' field which can be an int (ID) or a Map (full User object)
    if (json['user'] is Map<String, dynamic>) {
      parsedUser = User.fromJson(json['user']);
      extractedUserId = parsedUser.id; // Get ID from the parsed User object
    } else if (json['user'] is int) {
      extractedUserId = json['user'] as int;
      parsedUser = User.fromId(extractedUserId); // Create a User object from just the ID
    } else {
      // Fallback if 'user' field is missing or unexpected type
      // This might indicate an issue if user is always expected
      extractedUserId = json['user_id'] as int; // Try 'user_id' as a fallback
      parsedUser = User.fromId(extractedUserId);
      print('Warning: Student.fromJson received unexpected type for "user" field: ${json['user'].runtimeType}. Attempting to use user_id fallback.');
    }

    return Student(
      uuid: json['uuid'] as String, // Retrieve UUID (non-nullable)
      userId: extractedUserId, // Assign the extracted user ID
      user: parsedUser, // Assign the parsed User object
      studentIdCode: json['student_id_code'] as String?,
      gradeLevel: json['grade_level'] as String?,
      className: json['class_name'] as String?,
      dateRegistered: DateTime.parse(json['date_registered'] as String),
      lastDeviceSync: json['last_device_sync'] != null ? DateTime.parse(json['last_device_sync'] as String) : null,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      schoolName: json['school_name'] as String?,
      walletAddress: json['wallet_address'] as String?,
    );
  }

  // Helper for immutability and updating specific fields
  Student copyWith({
    String? uuid,
    int? userId,
    User? user,
    String? studentIdCode,
    String? gradeLevel,
    String? className,
    DateTime? dateRegistered,
    DateTime? lastDeviceSync,
    String? gender,
    DateTime? dateOfBirth,
    String? schoolName,
    String? walletAddress,
  }) {
    return Student(
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      className: className ?? this.className,
      dateRegistered: dateRegistered ?? this.dateRegistered,
      lastDeviceSync: lastDeviceSync ?? this.lastDeviceSync,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      schoolName: schoolName ?? this.schoolName,
      walletAddress: walletAddress ?? this.walletAddress,
    );
  }

  @override
  String toString() {
    return 'Student(uuid: $uuid, userId: $userId, username: ${user?.username}, studentIdCode: $studentIdCode)';
  }
}
