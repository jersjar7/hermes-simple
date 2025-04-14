// lib/data/services/firebase_service.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  DatabaseReference? _sessionsRef;
  StreamSubscription? _sessionSubscription;
  bool _isInitialized = false;
  bool _isConnected = false;
  String? _sessionId;

  // Stream controllers for messages
  final _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Expose stream for listeners
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  // Constructor with safe initialization
  FirebaseService() {
    _initializeFirebase();
  }

  // Safe initialization method
  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        _sessionsRef = FirebaseDatabase.instance.ref('sessions');
        _isInitialized = true;
        print('FirebaseService - initialized with existing Firebase app');
      } else {
        print(
          'FirebaseService - Firebase not initialized, features will be limited',
        );
        // Don't try to access Firebase services if not initialized
        _isInitialized = false;

        // Try to initialize Firebase as a fallback
        try {
          await Firebase.initializeApp();
          _sessionsRef = FirebaseDatabase.instance.ref('sessions');
          _isInitialized = true;
          print('FirebaseService - successfully initialized Firebase');
        } catch (initError) {
          print('FirebaseService - fallback initialization failed: $initError');
        }
      }
    } catch (e) {
      print('FirebaseService - initialization error: $e');
      _isInitialized = false;
      _messageStreamController.add({
        'type': 'error',
        'data': 'Firebase initialization error: $e',
      });
    }
  }

  // Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  // Connect to Firebase session
  Future<bool> connect({
    required String sessionCode,
    required String role,
  }) async {
    print(
      'FirebaseService - connect called for session: $sessionCode, role: $role',
    );

    // Check if Firebase is initialized
    if (!_isInitialized || _sessionsRef == null) {
      print('FirebaseService - not initialized, cannot connect');
      _messageStreamController.add({
        'type': 'error',
        'data': 'Firebase not initialized',
      });
      return false;
    }

    if (_isConnected) {
      print('FirebaseService - already connected, disconnecting first');
      await disconnect();
    }

    try {
      // Check if session exists
      final snapshot = await _sessionsRef!.child(sessionCode).get();
      if (!snapshot.exists) {
        // For speaker role, create the session
        if (role == 'speaker') {
          await _sessionsRef!.child(sessionCode).set({
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
      _sessionSubscription = _sessionsRef!
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
    // Check if Firebase is initialized
    if (!_isInitialized || _sessionsRef == null) {
      print('FirebaseService - not initialized, cannot check session');
      return false;
    }

    try {
      final snapshot = await _sessionsRef!.child(sessionCode).get();
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

    // Check if Firebase is initialized
    if (!_isInitialized || _sessionsRef == null) {
      print('FirebaseService - not initialized, cannot send message');
      return false;
    }

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

      await _sessionsRef!
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
