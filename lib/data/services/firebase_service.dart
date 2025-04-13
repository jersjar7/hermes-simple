// lib/data/services/firebase_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _sessionsRef = FirebaseDatabase.instance.ref(
    'sessions',
  );
  StreamSubscription? _sessionSubscription;
  bool _isConnected = false;
  String? _sessionId;

  // Stream controllers for messages
  final _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Expose stream for listeners
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  // Connect to Firebase session
  Future<bool> connect({
    required String sessionCode,
    required String role,
  }) async {
    print(
      'FirebaseService - connect called for session: $sessionCode, role: $role',
    );

    if (_isConnected) {
      print('FirebaseService - already connected, disconnecting first');
      await disconnect();
    }

    try {
      // Check if session exists
      final snapshot = await _sessionsRef.child(sessionCode).get();
      if (!snapshot.exists) {
        // For speaker role, create the session
        if (role == 'speaker') {
          await _sessionsRef.child(sessionCode).set({
            'created': ServerValue.timestamp,
            'active': true,
            'role': role,
          });
        } else {
          // For audience, session must exist
          print('FirebaseService - session does not exist: $sessionCode');
          return false;
        }
      }

      // Set up connection
      _sessionId = sessionCode;
      _isConnected = true;

      // Listen for messages in this session
      _sessionSubscription = _sessionsRef
          .child(sessionCode)
          .child('messages')
          .onChildAdded
          .listen((event) {
            final message = event.snapshot.value;
            if (message != null && message is Map) {
              _handleIncomingMessage(Map<String, dynamic>.from(message));
            }
          });

      // Notify connection status
      _messageStreamController.add({'type': 'status', 'data': 'connected'});

      print(
        'FirebaseService - connection established to session: $sessionCode',
      );
      return true;
    } catch (e) {
      print('FirebaseService - connection failed: $e');
      _isConnected = false;
      _messageStreamController.add({
        'type': 'error',
        'data': 'Connection error: $e',
      });
      return false;
    }
  }

  // Check if session exists (for audience validation)
  Future<bool> sessionExists(String sessionCode) async {
    try {
      final snapshot = await _sessionsRef.child(sessionCode).get();
      return snapshot.exists;
    } catch (e) {
      print('FirebaseService - error checking session: $e');
      return false;
    }
  }

  // Send a message to the session
  Future<bool> sendMessage({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    print('FirebaseService - sendMessage called, type: $type');

    if (!_isConnected || _sessionId == null) {
      print('FirebaseService - not connected, cannot send message');
      return false;
    }

    try {
      final message = {
        'type': type,
        'sessionId': _sessionId,
        'data': data,
        'timestamp': ServerValue.timestamp,
      };

      await _sessionsRef
          .child(_sessionId!)
          .child('messages')
          .push()
          .set(message);

      print('FirebaseService - message sent successfully');
      return true;
    } catch (e) {
      print('FirebaseService - error sending message: $e');
      return false;
    }
  }

  // Handle incoming messages
  void _handleIncomingMessage(Map<String, dynamic> message) {
    print('FirebaseService - received message: $message');

    // Add to stream for listeners
    _messageStreamController.add(message);
  }

  // Send a translation message
  Future<bool> sendTranslation({
    required String originalText,
    required String translatedText,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    print('FirebaseService - sendTranslation called');

    return sendMessage(
      type: 'translation',
      data: {
        'originalText': originalText,
        'translatedText': translatedText,
        'fromLanguage': fromLanguage,
        'toLanguage': toLanguage,
      },
    );
  }

  // Disconnect from the session
  Future<void> disconnect() async {
    print('FirebaseService - disconnect called');

    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _isConnected = false;
    _sessionId = null;

    _messageStreamController.add({'type': 'status', 'data': 'disconnected'});
    print('FirebaseService - disconnected');
  }

  // Check if connected to session
  bool get isConnected => _isConnected;

  // Dispose resources
  void dispose() {
    print('FirebaseService - dispose called');
    disconnect();
    _messageStreamController.close();
  }
}
