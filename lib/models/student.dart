// learnflow_ai/flutter_app/lib/models/student.dart

import 'package:learnflow_ai/models/user.dart';

class Student {
  final int userId; // Corresponds to Django User's primary key
  String? studentIdCode; // CHANGED: Made non-final to allow modification
  final DateTime dateRegistered;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? gradeLevel;
  final String? className;
  final String? schoolName;
  final DateTime? lastDeviceSync;
  final User? user; // Nested User object if fetched with student details

  Student({
    required this.userId,
    this.studentIdCode,
    required this.dateRegistered,
    this.dateOfBirth,
    this.gender,
    this.gradeLevel,
    this.className,
    this.schoolName,
    this.lastDeviceSync,
    this.user,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Debug print to see what student_id_code is being received
    print('Student.fromJson: Raw student_id_code from JSON: ${json['student_id_code']}');

    return Student(
      userId: json['user']['id'], // Assuming 'user' is always present and has 'id'
      studentIdCode: json['student_id_code'] as String?,
      dateRegistered: DateTime.parse(json['date_registered']),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'] as String?,
      gradeLevel: json['grade_level'] as String?,
      className: json['class_name'] as String?,
      schoolName: json['school_name'] as String?,
      lastDeviceSync: json['last_device_sync'] != null
          ? DateTime.parse(json['last_device_sync'])
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId, // Send user ID for Django's student serializer
      'student_id_code': studentIdCode,
      'date_registered': dateRegistered.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'grade_level': gradeLevel,
      'class_name': className,
      'school_name': schoolName,
      'last_device_sync': lastDeviceSync?.toIso8601String(),
    };
  }

  // Method to convert to a format suitable for local storage (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'student_id_code': studentIdCode,
      'date_registered': dateRegistered.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'grade_level': gradeLevel,
      'class_name': className,
      'school_name': schoolName,
      'last_device_sync': lastDeviceSync?.toIso8601String(),
    };
  }

  // Method to create from a map (for local storage retrieval)
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      userId: map['user_id'],
      studentIdCode: map['student_id_code'],
      dateRegistered: DateTime.parse(map['date_registered']),
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      gender: map['gender'],
      gradeLevel: map['grade_level'],
      className: map['class_name'],
      schoolName: map['school_name'],
      lastDeviceSync: map['last_device_sync'] != null
          ? DateTime.parse(map['last_device_sync'])
          : null,
      // User object is not stored directly in student table, so not parsed from map here
      user: null,
    );
  }

  // New: copyWith method for immutable updates (even though field is now mutable)
  Student copyWith({
    int? userId,
    String? studentIdCode,
    DateTime? dateRegistered,
    DateTime? dateOfBirth,
    String? gender,
    String? gradeLevel,
    String? className,
    String? schoolName,
    DateTime? lastDeviceSync,
    User? user,
  }) {
    return Student(
      userId: userId ?? this.userId,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      dateRegistered: dateRegistered ?? this.dateRegistered,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      className: className ?? this.className,
      schoolName: schoolName ?? this.schoolName,
      lastDeviceSync: lastDeviceSync ?? this.lastDeviceSync,
      user: user ?? this.user,
    );
  }
}
