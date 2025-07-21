// learnflow_ai/flutter_app/lib/models/quiz_attempt.dart

import 'package:uuid/uuid.dart'; // For generating UUIDs locally
import 'dart:convert'; // Added for jsonEncode/jsonDecode

class QuizAttempt {
  final String uuid; // Client-generated UUID for local tracking and sync
  final int studentUserId; // Student's User ID (PK from Django User model)
  final String? studentIdCode; // ADDED: Student's ID code for linking (from Student model)
  final String questionUuid; // UUID of the question attempted
  final String submittedAnswer;
  final bool isCorrect; // Whether the answer was correct
  final double score; // For short answers, or 0/1 for MCQ
  final String? aiFeedbackText;
  final Map<String, dynamic>? rawAiResponse; // Raw AI model output
  final DateTime attemptTimestamp; // When the attempt was made on device
  final DateTime? syncedAt; // When it was successfully synced to server
  final String syncStatus; // 'PENDING', 'SYNCED', 'CONFLICT'
  final String? deviceId; // Unique ID of the device

  QuizAttempt({
    String? uuid, // Optional: if creating a new one, it will be generated
    required this.studentUserId,
    this.studentIdCode, // ADDED
    required this.questionUuid,
    required this.submittedAnswer,
    required this.isCorrect,
    required this.score,
    this.aiFeedbackText,
    this.rawAiResponse,
    DateTime? attemptTimestamp, // Optional: if creating new, it will be now
    this.syncedAt,
    this.syncStatus = 'PENDING', // Default to PENDING for new attempts
    this.deviceId,
  }) :  uuid = uuid ?? const Uuid().v4(), // Generate UUID if not provided
        attemptTimestamp = attemptTimestamp ?? DateTime.now();


  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      uuid: json['uuid'],
      studentUserId: json['student'], // Django sends student (user) ID
      studentIdCode: json['student_id_code'], // ADDED
      questionUuid: json['question_uuid'] ?? '',
      submittedAnswer: json['submitted_answer'],
      isCorrect: json['is_correct'] ?? false, // Default to false if null from JSON
      score: json['score']?.toDouble() ?? 0.0, // Default to 0.0 if null from JSON
      aiFeedbackText: json['ai_feedback_text'],
      rawAiResponse: json['raw_ai_response'] != null
          ? Map<String, dynamic>.from(json['raw_ai_response'])
          : null,
      attemptTimestamp: DateTime.parse(json['attempt_timestamp']),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : null,
      syncStatus: json['sync_status'] ?? 'PENDING',
      deviceId: json['device_id'],
    );
  }

  // To send to Django API
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {
      'uuid': uuid,
      'student': studentUserId, // Still send user ID as Django might need it for related objects
      'student_id_code': studentIdCode, // ADDED: Send student_id_code to satisfy Django serializer
      'question_uuid': questionUuid,
      'submitted_answer': submittedAnswer,
      'is_correct': isCorrect,
      'score': score,
      'ai_feedback_text': aiFeedbackText,
      'raw_ai_response': rawAiResponse, // rawAiResponse is already a Map, no need to encode here for API
      'attempt_timestamp': attemptTimestamp.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'device_id': deviceId,
    };
    print('QuizAttempt.toJson() payload: $jsonMap'); // DEBUG PRINT
    return jsonMap;
  }

  // To store in local SQLite database
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'student_user_id': studentUserId,
      'student_id_code': studentIdCode, // ADDED
      'question_uuid': questionUuid,
      'submitted_answer': submittedAnswer,
      'is_correct': isCorrect ? 1 : 0, // SQLite stores bool as int
      'score': score,
      'ai_feedback_text': aiFeedbackText,
      'raw_ai_response': rawAiResponse != null ? jsonEncode(rawAiResponse!) : null, // Encode Map to JSON string
      'attempt_timestamp': attemptTimestamp.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'device_id': deviceId,
    };
  }

  // To retrieve from local SQLite database
  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      uuid: map['uuid'],
      studentUserId: map['student_user_id'],
      studentIdCode: map['student_id_code'], // ADDED
      questionUuid: map['question_uuid'],
      submittedAnswer: map['submitted_answer'],
      isCorrect: map['is_correct'] == 1, // Convert int back to bool
      score: map['score']?.toDouble() ?? 0.0,
      aiFeedbackText: map['ai_feedback_text'],
      rawAiResponse: map['raw_ai_response'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['raw_ai_response'])) // Decode JSON string to Map
          : null,
      attemptTimestamp: DateTime.parse(map['attempt_timestamp']),
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'])
          : null,
      syncStatus: map['sync_status'],
      deviceId: map['device_id'],
    );
  }

  // New: copyWith method for immutable updates
  QuizAttempt copyWith({
    String? uuid,
    int? studentUserId,
    String? studentIdCode, // ADDED
    String? questionUuid,
    String? submittedAnswer,
    bool? isCorrect,
    double? score,
    String? aiFeedbackText,
    Map<String, dynamic>? rawAiResponse,
    DateTime? attemptTimestamp,
    DateTime? syncedAt,
    String? syncStatus,
    String? deviceId,
  }) {
    return QuizAttempt(
      uuid: uuid ?? this.uuid,
      studentUserId: studentUserId ?? this.studentUserId,
      studentIdCode: studentIdCode ?? this.studentIdCode, // ADDED
      questionUuid: questionUuid ?? this.questionUuid,
      submittedAnswer: submittedAnswer ?? this.submittedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      aiFeedbackText: aiFeedbackText ?? this.aiFeedbackText,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      attemptTimestamp: attemptTimestamp ?? this.attemptTimestamp,
      syncedAt: syncedAt ?? this.syncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
