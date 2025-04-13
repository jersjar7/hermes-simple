// lib/data/services/speech_service.dart

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../core/constants/app_constants.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Initialize the speech recognition service
  Future<bool> initialize() async {
    print('SpeechService - initialize called');

    if (_isInitialized) {
      print('SpeechService - already initialized');
      return true;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          print('SpeechService - recognition error: ${error.errorMsg}');
        },
        onStatus: (String status) {
          print('SpeechService - recognition status: $status');
        },
        debugLogging: true, // Enable debug logging
      );

      print(
        'SpeechService - initialization completed with result: $_isInitialized',
      );

      if (_isInitialized) {
        // Log available languages
        final languages = await _speechToText.locales();
        print('SpeechService - available languages: ${languages.length}');
        for (var locale in languages.take(5)) {
          // Log just first 5 to avoid too much noise
          print('SpeechService - locale: ${locale.localeId} - ${locale.name}');
        }
      }

      return _isInitialized;
    } catch (e) {
      print('SpeechService - initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  // Check if speech recognition is currently active
  bool get isListening => _speechToText.isListening;

  // Get available languages
  Future<List<LocaleName>> getAvailableLanguages() async {
    print('SpeechService - getAvailableLanguages called');
    if (!_isInitialized) {
      print('SpeechService - not initialized, initializing now');
      await initialize();
    }

    final languages = await _speechToText.locales();
    print('SpeechService - found ${languages.length} languages');
    return languages;
  }

  // Start listening for speech
  Future<void> startListening({
    required Function(String text) onResult,
    String? selectedLocaleId,
  }) async {
    print(
      'SpeechService - startListening called with locale: $selectedLocaleId',
    );

    if (!_isInitialized) {
      print('SpeechService - not initialized, initializing now');
      await initialize();
    }

    if (!_isInitialized) {
      print('SpeechService - failed to initialize, cannot start listening');
      throw Exception('Speech recognition service failed to initialize');
    }

    try {
      print('SpeechService - starting to listen');
      final success = await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          final recognizedWords = result.recognizedWords;
          print(
            'SpeechService - got result, partial: ${result.finalResult}, words: ${recognizedWords.length}',
          );
          if (recognizedWords.isNotEmpty) {
            onResult(recognizedWords);
          }
        },
        listenFor: Duration(milliseconds: AppConstants.listeningTimeout),
        localeId: selectedLocaleId,
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.confirmation,
      );

      print('SpeechService - listen method returned: $success');

      if (!success) {
        print('SpeechService - failed to start listening');
        throw Exception('Failed to start speech recognition');
      }
    } catch (e) {
      print('SpeechService - error in startListening: $e');
      throw Exception('Error starting speech recognition: $e');
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    print('SpeechService - stopListening called');
    try {
      await _speechToText.stop();
      print('SpeechService - stopped listening');
    } catch (e) {
      print('SpeechService - error in stopListening: $e');
      throw Exception('Error stopping speech recognition: $e');
    }
  }

  // Dispose resources
  void dispose() {
    print('SpeechService - dispose called');
    _speechToText.cancel();
  }
}
