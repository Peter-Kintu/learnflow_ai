// learnflow_ai/flutter_app/lib/models/lesson.dart

import 'package:uuid/uuid.dart';

class Lesson {
  final String uuid;
  final String title;
  final String? description;
  final String? subject;
  final String? difficultyLevel;
  final int version;
  final String? coverImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.uuid,
    required this.title,
    this.description,
    this.subject,
    this.difficultyLevel,
    this.version = 1,
    this.coverImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      version: json['version'] as int,
      coverImageUrl: json['cover_image_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'version': version,
      'cover_image_url': coverImageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}