// learnflow_ai/flutter_app/lib/models/quiz_attempt.dart

import 'package:uuid/uuid.dart'; // For generating UUIDs

class QuizAttempt {
  final String uuid;
  final int studentUserId;
  final String? studentIdCode; // Added to match backend
  final String questionUuid;
  final String submittedAnswer;
  final bool isCorrect;
  final double score;
  final String? aiFeedbackText;
  final String? rawAiResponse; // Store raw AI response for debugging/analysis
  final DateTime attemptTimestamp;
  DateTime? syncedAt; // When it was last synced to the backend
  String syncStatus; // 'PENDING', 'SYNCED', 'CONFLICT' (for future)
  final String deviceId; // Identifier for the device that made the attempt

  // New fields for display purposes in the UI (e.g., SyncStatusScreen)
  final String? lessonTitle;
  final String? questionTextPreview;

  QuizAttempt({
    required this.uuid,
    required this.studentUserId,
    this.studentIdCode, // Made optional as it might be generated/fetched later
    required this.questionUuid,
    required this.submittedAnswer,
    required this.isCorrect,
    required this.score,
    this.aiFeedbackText,
    this.rawAiResponse,
    required this.attemptTimestamp,
    this.syncedAt,
    this.syncStatus = 'PENDING', // Default to PENDING
    required this.deviceId,
    this.lessonTitle, // Initialize new fields
    this.questionTextPreview, // Initialize new fields
  });

  // Convert a QuizAttempt object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'student_user_id': studentUserId,
      'student_id_code': studentIdCode, // Include in map
      'question_uuid': questionUuid,
      'submitted_answer': submittedAnswer,
      'is_correct': isCorrect ? 1 : 0, // SQLite stores bool as int
      'score': score,
      'ai_feedback_text': aiFeedbackText,
      'raw_ai_response': rawAiResponse,
      'attempt_timestamp': attemptTimestamp.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'device_id': deviceId,
      'lesson_title': lessonTitle, // Include in map
      'question_text_preview': questionTextPreview, // Include in map
    };
  }

  // Convert a Map object into a QuizAttempt object (from SQLite)
  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      uuid: map['uuid'] as String,
      studentUserId: map['student_user_id'] as int,
      studentIdCode: map['student_id_code'] as String?, // Explicit cast
      questionUuid: map['question_uuid'] as String,
      submittedAnswer: map['submitted_answer'] as String,
      isCorrect: map['is_correct'] == 1,
      score: map['score'] as double,
      aiFeedbackText: map['ai_feedback_text'] as String?, // Explicit cast
      rawAiResponse: map['raw_ai_response'] as String?, // Explicit cast here
      attemptTimestamp: DateTime.parse(map['attempt_timestamp'] as String),
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
      syncStatus: map['sync_status'] as String,
      deviceId: map['device_id'] as String,
      lessonTitle: map['lesson_title'] as String?, // Explicit cast
      questionTextPreview: map['question_text_preview'] as String?, // Explicit cast
    );
  }

  // Convert a QuizAttempt object into a JSON object (for API)
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'student_user_id': studentUserId,
      'student_id_code': studentIdCode, // Include in JSON
      'question_uuid': questionUuid,
      'submitted_answer': submittedAnswer,
      'is_correct': isCorrect,
      'score': score,
      'ai_feedback_text': aiFeedbackText,
      'raw_ai_response': rawAiResponse,
      'attempt_timestamp': attemptTimestamp.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'device_id': deviceId,
      // lessonTitle and questionTextPreview are not sent to backend,
      // they are for local UI display only.
    };
  }

  // Factory constructor to create a QuizAttempt from JSON (from API)
  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      uuid: json['uuid'] as String,
      studentUserId: json['student_user_id'] as int,
      studentIdCode: json['student_id_code'] as String?,
      questionUuid: json['question_uuid'] as String,
      submittedAnswer: json['submitted_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      score: json['score']?.toDouble() as double, // Ensure it's a double
      aiFeedbackText: json['ai_feedback_text'] as String?,
      rawAiResponse: json['raw_ai_response'] as String?, // Explicit cast here
      attemptTimestamp: DateTime.parse(json['attempt_timestamp'] as String),
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at'] as String) : null,
      syncStatus: json['sync_status'] as String,
      deviceId: json['device_id'] as String,
      // These fields might not be present in API response, so handle null
      lessonTitle: json['lesson_title'] as String?,
      questionTextPreview: json['question_text_preview'] as String?,
    );
  }

  // Helper for immutability and updating specific fields
  QuizAttempt copyWith({
    String? uuid,
    int? studentUserId,
    String? studentIdCode,
    String? questionUuid,
    String? submittedAnswer,
    bool? isCorrect,
    double? score,
    String? aiFeedbackText,
    String? rawAiResponse, // Explicitly String? here
    DateTime? attemptTimestamp,
    DateTime? syncedAt,
    String? syncStatus,
    String? deviceId,
    String? lessonTitle,
    String? questionTextPreview,
  }) {
    return QuizAttempt(
      uuid: uuid ?? this.uuid,
      studentUserId: studentUserId ?? this.studentUserId,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      questionUuid: questionUuid ?? this.questionUuid,
      submittedAnswer: submittedAnswer ?? this.submittedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      aiFeedbackText: aiFeedbackText ?? this.aiFeedbackText,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse, // This line is the fix
      attemptTimestamp: attemptTimestamp ?? this.attemptTimestamp,
      syncedAt: syncedAt ?? this.syncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      questionTextPreview: questionTextPreview ?? this.questionTextPreview,
    );
  }
}
