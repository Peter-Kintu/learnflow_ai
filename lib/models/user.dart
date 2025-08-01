// learnflow_ai/flutter_app/lib/models/user.dart

class User {
  final int id; // User ID (Primary Key)
  final String? username; // Made nullable
  final String? email;    // Made nullable
  final bool isStaff; // To distinguish between student and teacher/admin

  User({
    required this.id, // ID is required once a User object is created/fetched
    this.username,
    this.email,
    this.isStaff = false,
  });

  // Factory constructor to create a User from a Map (e.g., from API or SQLite)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String?, // Handle nullable
      email: map['email'] as String?,       // Handle nullable
      isStaff: (map['is_staff'] as int? ?? 0) == 1, // SQLite stores bool as int
    );
  }

  // Factory constructor to create a User from JSON (from API)
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle cases where 'id' might come as 'user_id' or just 'id'
    final int? userId = json['user_id'] ?? json['id'];
    if (userId == null) {
      throw FormatException("User ID is missing from JSON: $json");
    }

    return User(
      id: userId,
      username: json['username'] as String?, // Handle nullable
      email: json['email'] as String?,       // Handle nullable
      isStaff: json['is_staff'] as bool? ?? false, // Default to false if not provided
    );
  }

  // New factory constructor to create a User object when only the ID is known
  factory User.fromId(int id) {
    return User(id: id, username: null, email: null, isStaff: false);
  }

  // Convert a User object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_staff': isStaff ? 1 : 0, // SQLite stores boolean as integer
    };
  }

  // Convert a User object into a JSON object (for API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_staff': isStaff,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, isStaff: $isStaff)';
  }
}
