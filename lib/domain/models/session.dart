// lib/domain/models/session.dart

class Session {
  final String sessionCode;
  final DateTime createdAt;
  final String speakerLanguage;

  Session({
    required this.sessionCode,
    required this.createdAt,
    required this.speakerLanguage,
  });

  // Factory constructor to create from Map (for future persistence)
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      sessionCode: map['sessionCode'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      speakerLanguage: map['speakerLanguage'] as String,
    );
  }

  // Convert to Map (for future persistence)
  Map<String, dynamic> toMap() {
    return {
      'sessionCode': sessionCode,
      'createdAt': createdAt.toIso8601String(),
      'speakerLanguage': speakerLanguage,
    };
  }
}
