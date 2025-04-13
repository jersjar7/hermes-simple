// lib/presentation/providers/session_provider.dart

import 'package:flutter/foundation.dart';
import '../../domain/models/session.dart';
import '../../domain/models/user_role.dart';
import '../../core/utils/session_code_generator.dart';

class SessionProvider with ChangeNotifier {
  Session? _currentSession;
  UserRole _userRole = UserRole.none;
  String? _joinedSessionCode;

  Session? get currentSession => _currentSession;
  UserRole get userRole => _userRole;
  String? get joinedSessionCode => _joinedSessionCode;

  bool get isSessionActive =>
      _currentSession != null || _joinedSessionCode != null;

  // Set user role
  void setUserRole(UserRole role) {
    print('SessionProvider - setUserRole: $role');
    _userRole = role;
    notifyListeners();
  }

  // Create a new session for speaker
  void createSession(String speakerLanguage) {
    print('SessionProvider - createSession with language: $speakerLanguage');

    // Check if session already exists to avoid duplicate creation
    if (_currentSession != null) {
      print('SessionProvider - session already exists, skipping creation');
      return;
    }

    final sessionCode = SessionCodeGenerator.generateSessionCode();
    print('SessionProvider - generated session code: $sessionCode');

    _currentSession = Session(
      sessionCode: sessionCode,
      createdAt: DateTime.now(),
      speakerLanguage: speakerLanguage,
    );

    _userRole = UserRole.speaker;
    notifyListeners();
    print('SessionProvider - session created successfully');
  }

  // Join a session for audience
  bool joinSession(String sessionCode) {
    print('SessionProvider - joinSession with code: $sessionCode');

    if (!SessionCodeGenerator.isValidSessionCode(sessionCode)) {
      print('SessionProvider - invalid session code format');
      return false;
    }

    // In MVP, we'll just store the session code without validation
    // In a future phase, we'd validate the code against a backend
    _joinedSessionCode = sessionCode;
    _userRole = UserRole.audience;
    notifyListeners();
    print('SessionProvider - joined session successfully');
    return true;
  }

  // End the current session
  void endSession() {
    print('SessionProvider - endSession called');
    _currentSession = null;
    _joinedSessionCode = null;
    _userRole = UserRole.none;
    notifyListeners();
    print('SessionProvider - session ended');
  }
}
