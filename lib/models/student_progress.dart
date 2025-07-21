// learnflow_ai/flutter_app/lib/models/student_progress.dart

import 'dart:convert'; // For JSON encoding/decoding

class StudentProgress {
  final String uuid; // UUID from Django
  final int studentUserId; // Student's primary key from Django (User ID)
  final Map<String, dynamic> overallProgressData; // JSON field for detailed progress
  final DateTime lastUpdated;
  final List<String> completedLessons; // List of lesson UUIDs
  final Map<String, dynamic> quizScores; // Map of lesson UUID to score or detailed quiz results

  StudentProgress({
    required this.uuid,
    required this.studentUserId, // Changed from studentId
    required this.overallProgressData,
    required this.lastUpdated,
    required this.completedLessons,
    required this.quizScores,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      uuid: json['uuid'],
      studentUserId: json['student'], // Django's ForeignKey to Student is the student ID (PK)
      overallProgressData: json['overall_progress_data'] != null
          ? Map<String, dynamic>.from(json['overall_progress_data'])
          : {},
      lastUpdated: DateTime.parse(json['last_updated']),
      completedLessons: List<String>.from(json['completed_lessons'] ?? []),
      quizScores: Map<String, dynamic>.from(json['quiz_scores'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'student': studentUserId, // Send student's user ID
      'overall_progress_data': overallProgressData,
      'last_updated': lastUpdated.toIso8601String(),
      'completed_lessons': completedLessons,
      'quiz_scores': quizScores,
    };
  }

  // Method to convert to a format suitable for local storage (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'student_user_id': studentUserId, // Use student_user_id for local DB
      'overall_progress_data': jsonEncode(overallProgressData), // Store JSON as string
      'last_updated': lastUpdated.toIso8601String(),
      'completed_lessons': jsonEncode(completedLessons), // Store List as JSON string
      'quiz_scores': jsonEncode(quizScores), // Store Map as JSON string
    };
  }

  // Method to create from a map (for local storage retrieval)
  factory StudentProgress.fromMap(Map<String, dynamic> map) {
    return StudentProgress(
      uuid: map['uuid'],
      studentUserId: map['student_user_id'],
      overallProgressData: map['overall_progress_data'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['overall_progress_data']))
          : {},
      lastUpdated: DateTime.parse(map['last_updated']),
      completedLessons: map['completed_lessons'] != null
          ? List<String>.from(jsonDecode(map['completed_lessons'] as String))
          : [],
      quizScores: map['quiz_scores'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['quiz_scores'] as String))
          : {},
    );
  }
}
