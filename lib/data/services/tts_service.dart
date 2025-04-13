// lib/data/services/tts_service.dart

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';

  // Initialize the TTS service
  Future<bool> initialize() async {
    print('TTSService - initialize called');

    if (_isInitialized) {
      print('TTSService - already initialized');
      return true;
    }

    try {
      // Set default properties
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(
        0.5,
      ); // Slightly slower for better understanding
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Setup completion listener for debugging
      _flutterTts.setCompletionHandler(() {
        print('TTSService - speech completed');
      });

      // Setup error listener
      _flutterTts.setErrorHandler((error) {
        print('TTSService - error: $error');
      });

      _isInitialized = true;
      print('TTSService - successfully initialized');
      return true;
    } catch (e) {
      print('TTSService - initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    print('TTSService - getAvailableLanguages called');

    try {
      final languages = await _flutterTts.getLanguages;
      print('TTSService - available languages: $languages');
      return List<String>.from(languages);
    } catch (e) {
      print('TTSService - error getting languages: $e');
      return [];
    }
  }

  // Set language
  Future<bool> setLanguage(String languageCode) async {
    print('TTSService - setLanguage called: $languageCode');

    try {
      // Map complex language codes to TTS language codes
      final ttsLanguageCode = _getTTSLanguageCode(languageCode);
      await _flutterTts.setLanguage(ttsLanguageCode);
      _currentLanguage = ttsLanguageCode;
      print('TTSService - language set to: $ttsLanguageCode');
      return true;
    } catch (e) {
      print('TTSService - error setting language: $e');
      return false;
    }
  }

  // Speak text
  Future<bool> speak(String text) async {
    print('TTSService - speak called with text: "$text"');

    if (!_isInitialized) {
      print('TTSService - not initialized, initializing first');
      final initialized = await initialize();
      if (!initialized) {
        print('TTSService - initialization failed, cannot speak');
        return false;
      }
    }

    if (text.isEmpty) {
      print('TTSService - empty text, nothing to speak');
      return false;
    }

    try {
      await _flutterTts.speak(text);
      print('TTSService - speaking started');
      return true;
    } catch (e) {
      print('TTSService - error speaking: $e');
      return false;
    }
  }

  // Stop speaking
  Future<bool> stop() async {
    print('TTSService - stop called');

    try {
      await _flutterTts.stop();
      print('TTSService - speaking stopped');
      return true;
    } catch (e) {
      print('TTSService - error stopping speech: $e');
      return false;
    }
  }

  // Convert our language codes to TTS language codes
  String _getTTSLanguageCode(String languageCode) {
    // Map display names to language codes
    final Map<String, String> codeMapping = {
      'English (US)': 'en-US',
      'Spanish': 'es-ES',
      'French': 'fr-FR',
      'German': 'de-DE',
      'Chinese': 'zh-CN',
    };

    return codeMapping[languageCode] ?? languageCode;
  }

  // Dispose resources
  void dispose() {
    print('TTSService - dispose called');
    _flutterTts.stop();
  }

  // Check if TTS service is initialized
  bool get isInitialized => _isInitialized;
}
