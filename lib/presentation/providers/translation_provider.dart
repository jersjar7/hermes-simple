// lib/presentation/providers/translation_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/services/translation_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/websocket_service.dart';

class TranslationProvider with ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  final TTSService _ttsService = TTSService();
  final WebSocketService _webSocketService = WebSocketService();

  bool _isInitialized = false;
  bool _isTranslating = false;
  bool _isSpeaking = false;
  bool _isConnected = false;
  String _error = '';

  String _speakerLanguage = 'en-US';
  String _audienceLanguage = 'en-US';
  String _lastOriginalText = '';
  String _lastTranslatedText = '';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTranslating => _isTranslating;
  bool get isSpeaking => _isSpeaking;
  bool get isConnected => _isConnected;
  String get error => _error;
  String get speakerLanguage => _speakerLanguage;
  String get audienceLanguage => _audienceLanguage;
  String get lastOriginalText => _lastOriginalText;
  String get lastTranslatedText => _lastTranslatedText;

  // Initialize all services
  Future<bool> initialize() async {
    print('TranslationProvider - initializing services');

    if (_isInitialized) {
      print('TranslationProvider - already initialized');
      return true;
    }

    _error = '';
    bool allInitialized = true;

    // Initialize translation service
    try {
      final translationInitialized = await _translationService.initialize();
      if (!translationInitialized) {
        print(
          'TranslationProvider - translation service initialization failed',
        );
        _error += 'Translation service initialization failed. ';
        allInitialized = false;
      }
    } catch (e) {
      print('TranslationProvider - translation service error: $e');
      _error += 'Translation error: $e. ';
      allInitialized = false;
    }

    // Initialize TTS service
    try {
      final ttsInitialized = await _ttsService.initialize();
      if (!ttsInitialized) {
        print('TranslationProvider - TTS service initialization failed');
        _error += 'Text-to-speech initialization failed. ';
        allInitialized = false;
      }
    } catch (e) {
      print('TranslationProvider - TTS service error: $e');
      _error += 'Text-to-speech error: $e. ';
      allInitialized = false;
    }

    // Set up WebSocket message listener
    _webSocketService.messageStream.listen((message) {
      _handleWebSocketMessage(message);
    });

    _isInitialized = allInitialized;
    notifyListeners();

    print(
      'TranslationProvider - initialization complete, success: $_isInitialized',
    );
    return _isInitialized;
  }

  // Set speaker language
  void setSpeakerLanguage(String language) {
    print('TranslationProvider - setting speaker language: $language');
    _speakerLanguage = language;
    notifyListeners();
  }

  // Set audience language
  void setAudienceLanguage(String language) async {
    print('TranslationProvider - setting audience language: $language');
    _audienceLanguage = language;

    // Update TTS language
    await _ttsService.setLanguage(language);

    notifyListeners();
  }

  // Connect to WebSocket
  Future<bool> connectToSession({
    required String sessionCode,
    required String role,
  }) async {
    print('TranslationProvider - connecting to session: $sessionCode as $role');

    _error = '';

    try {
      final connected = await _webSocketService.connect(
        sessionCode: sessionCode,
        role: role,
      );

      _isConnected = connected;

      if (!connected) {
        _error = 'Failed to connect to session';
        print('TranslationProvider - connection failed');
      } else {
        print('TranslationProvider - connected successfully');
      }

      notifyListeners();
      return connected;
    } catch (e) {
      _error = 'Connection error: $e';
      _isConnected = false;
      notifyListeners();
      print('TranslationProvider - connection error: $e');
      return false;
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    print('TranslationProvider - disconnecting');

    await _webSocketService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  // Translate text
  Future<String> translateText(String text) async {
    print('TranslationProvider - translateText called with: "$text"');

    if (text.isEmpty) {
      print('TranslationProvider - empty text, nothing to translate');
      return '';
    }

    _isTranslating = true;
    _error = '';
    _lastOriginalText = text;
    notifyListeners();

    try {
      final translatedText = await _translationService.translateText(
        text: text,
        fromLanguage: _speakerLanguage,
        toLanguage: _audienceLanguage,
      );

      _lastTranslatedText = translatedText;
      _isTranslating = false;

      // If connected to session, send translation to WebSocket
      if (_isConnected) {
        await _webSocketService.sendTranslation(
          originalText: text,
          translatedText: translatedText,
          fromLanguage: _speakerLanguage,
          toLanguage: _audienceLanguage,
        );
      }

      notifyListeners();
      return translatedText;
    } catch (e) {
      print('TranslationProvider - translation error: $e');
      _error = 'Translation error: $e';
      _isTranslating = false;
      notifyListeners();
      return 'Error: $e';
    }
  }

  // Speak translated text
  Future<bool> speakTranslatedText(String text) async {
    print('TranslationProvider - speakTranslatedText called with: "$text"');

    if (text.isEmpty) {
      print('TranslationProvider - empty text, nothing to speak');
      return false;
    }

    _isSpeaking = true;
    _error = '';
    notifyListeners();

    try {
      // Make sure TTS is using the correct language
      await _ttsService.setLanguage(_audienceLanguage);

      final success = await _ttsService.speak(text);
      _isSpeaking = false;

      if (!success) {
        _error = 'Failed to speak text';
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('TranslationProvider - TTS error: $e');
      _error = 'Text-to-speech error: $e';
      _isSpeaking = false;
      notifyListeners();
      return false;
    }
  }

  // Stop speaking
  Future<bool> stopSpeaking() async {
    print('TranslationProvider - stopSpeaking called');

    try {
      final success = await _ttsService.stop();
      _isSpeaking = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('TranslationProvider - stop speaking error: $e');
      return false;
    }
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    print('TranslationProvider - handling WebSocket message: $message');

    final String messageType = message['type'] ?? '';

    if (messageType == 'translation') {
      final data = message['data'];
      if (data != null && data is Map<String, dynamic>) {
        _lastOriginalText = data['originalText'] ?? '';
        _lastTranslatedText = data['translatedText'] ?? '';

        // Auto-speak for audience
        if (_audienceLanguage == data['toLanguage']) {
          speakTranslatedText(_lastTranslatedText);
        }

        notifyListeners();
      }
    } else if (messageType == 'error') {
      _error = message['data'] ?? 'Unknown error';
      notifyListeners();
    }
  }

  // Perform full pipeline: translate and speak text
  Future<bool> processText(String text) async {
    print('TranslationProvider - processText called with: "$text"');

    if (text.isEmpty) {
      print('TranslationProvider - empty text, nothing to process');
      return false;
    }

    // Skip if already processing
    if (_isTranslating || _isSpeaking) {
      print('TranslationProvider - already processing, skipping');
      return false;
    }

    try {
      // Translate the text
      final translatedText = await translateText(text);

      // If translation succeeded, speak it
      if (translatedText.isNotEmpty && !translatedText.startsWith('Error:')) {
        return await speakTranslatedText(translatedText);
      } else {
        return false;
      }
    } catch (e) {
      print('TranslationProvider - process error: $e');
      _error = 'Processing error: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear any error messages
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    print('TranslationProvider - dispose called');
    _ttsService.dispose();
    _webSocketService.dispose();
    super.dispose();
  }
}
