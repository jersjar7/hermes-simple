// lib/data/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _sessionId;

  // In MVP, use a mock implementation that simulates WebSocket
  final bool _useMockImplementation = true; // Set to true for development

  // Stream controllers for messages
  final _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Expose stream for listeners
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  // Connect to WebSocket server
  Future<bool> connect({
    required String sessionCode,
    required String role,
  }) async {
    print(
      'WebSocketService - connect called for session: $sessionCode, role: $role',
    );

    if (_isConnected) {
      print('WebSocketService - already connected, disconnecting first');
      await disconnect();
    }

    try {
      if (_useMockImplementation) {
        // For MVP, simulate a successful connection without actual WebSocket
        print('WebSocketService - using mock implementation');
        _isConnected = true;
        _sessionId = sessionCode;

        // Simulate connection success event
        _messageStreamController.add({'type': 'status', 'data': 'connected'});

        print('WebSocketService - mock connection established');
        return true;
      }

      // Real implementation (for future use)
      final Uri uri = Uri.parse(
        'wss://echo.websocket.org',
      ); // Temporary echo server for testing
      _channel = WebSocketChannel.connect(uri);
      _sessionId = sessionCode;

      // Set up connection
      _isConnected = true;
      print(
        'WebSocketService - connection established to session: $sessionCode',
      );

      // Listen for incoming messages
      _channel!.stream.listen(
        (dynamic message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print('WebSocketService - connection error: $error');
          _isConnected = false;
          _messageStreamController.add({
            'type': 'error',
            'data': 'Connection error: $error',
          });
        },
        onDone: () {
          print('WebSocketService - connection closed');
          _isConnected = false;
          _messageStreamController.add({
            'type': 'status',
            'data': 'disconnected',
          });
        },
      );

      return true;
    } catch (e) {
      print('WebSocketService - connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  // Send a message to the WebSocket server
  Future<bool> sendMessage({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    print('WebSocketService - sendMessage called, type: $type');
    print('WebSocketService - message data: $data');

    if (!_isConnected) {
      print('WebSocketService - not connected, cannot send message');
      return false;
    }

    try {
      final message = {
        'type': type,
        'sessionId': _sessionId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_useMockImplementation) {
        // For MVP, simulate message sending and echo it back
        print('WebSocketService - mock sending message: $message');

        // Simulate a delay
        Future.delayed(const Duration(milliseconds: 300), () {
          // Echo the message back to simulate receiving it
          _messageStreamController.add(message);
        });

        return true;
      }

      final jsonMessage = jsonEncode(message);
      print('WebSocketService - sending: $jsonMessage');

      _channel!.sink.add(jsonMessage);
      return true;
    } catch (e) {
      print('WebSocketService - error sending message: $e');
      return false;
    }
  }

  // Handle incoming messages
  void _handleIncomingMessage(dynamic message) {
    print('WebSocketService - received message: $message');

    try {
      final Map<String, dynamic> parsedMessage =
          message is String ? jsonDecode(message) : message;

      print('WebSocketService - parsed message: $parsedMessage');

      // Add to stream for listeners
      _messageStreamController.add(parsedMessage);
    } catch (e) {
      print('WebSocketService - error parsing message: $e');
    }
  }

  // Send a translation message
  Future<bool> sendTranslation({
    required String originalText,
    required String translatedText,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    print('WebSocketService - sendTranslation called');

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

  // Disconnect from the WebSocket server
  Future<void> disconnect() async {
    print('WebSocketService - disconnect called');

    if (_useMockImplementation) {
      _isConnected = false;
      _sessionId = null;
      _messageStreamController.add({'type': 'status', 'data': 'disconnected'});
      print('WebSocketService - mock disconnected');
      return;
    }

    if (_channel != null) {
      _channel!.sink.close(status.normalClosure);
      _channel = null;
      _isConnected = false;
      print('WebSocketService - disconnected');
    }
  }

  // Check if connected to WebSocket server
  bool get isConnected => _isConnected;

  // Dispose resources
  void dispose() {
    print('WebSocketService - dispose called');
    disconnect();
    _messageStreamController.close();
  }
}
