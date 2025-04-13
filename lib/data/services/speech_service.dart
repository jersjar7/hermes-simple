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
      print('SpeechService - attempting initialization with timeout');

      // Add a timeout to prevent hanging during initialization
      _isInitialized = await _speechToText
          .initialize(
            onError: (SpeechRecognitionError error) {
              print('SpeechService - recognition error: ${error.errorMsg}');
            },
            onStatus: (String status) {
              print('SpeechService - recognition status: $status');
            },
            debugLogging: true,
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('SpeechService - initialization timed out');
              return false;
            },
          );

      print('SpeechService - initialization result: $_isInitialized');

      if (_isInitialized) {
        print('SpeechService - successfully initialized');
      } else {
        print('SpeechService - initialization failed or timed out');
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

  // Start listening for speech
  Future<bool> startListening({
    required Function(String text) onResult,
    String? selectedLocaleId,
  }) async {
    print(
      'SpeechService - startListening called with locale: $selectedLocaleId',
    );

    // Make sure we're initialized before trying to listen
    if (!_isInitialized) {
      print('SpeechService - not initialized, initializing now');
      final initialized = await initialize();
      if (!initialized) {
        print('SpeechService - initialization failed, cannot start listening');
        return false;
      }
    }

    try {
      print('SpeechService - starting to listen');

      // Simple configuration for initial implementation
      final success = await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          final recognizedWords = result.recognizedWords;
          print(
            'SpeechService - got result: "${recognizedWords.isEmpty ? "(empty)" : recognizedWords}"',
          );
          print(
            'SpeechService - result details: final=${result.finalResult}, confidence=${result.confidence}',
          );

          if (recognizedWords.isNotEmpty) {
            onResult(recognizedWords);
          }
        },
        listenFor: Duration(milliseconds: AppConstants.listeningTimeout),
        localeId: selectedLocaleId,
        cancelOnError: false,
        partialResults: true,
      );

      print('SpeechService - listen method returned: $success');
      return success;
    } catch (e) {
      print('SpeechService - error in startListening: $e');
      return false;
    }
  }

  // Stop listening
  Future<bool> stopListening() async {
    print('SpeechService - stopListening called');

    if (!_speechToText.isListening) {
      print('SpeechService - not currently listening, nothing to stop');
      return true;
    }

    try {
      await _speechToText.stop();
      print('SpeechService - stopped listening successfully');
      return true;
    } catch (e) {
      print('SpeechService - error in stopListening: $e');
      return false;
    }
  }

  // Cancel listening (emergency stop)
  Future<bool> cancelListening() async {
    print('SpeechService - cancelListening called');
    try {
      await _speechToText.cancel();
      print('SpeechService - canceled listening successfully');
      return true;
    } catch (e) {
      print('SpeechService - error in cancelListening: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    print('SpeechService - dispose called');
    if (_speechToText.isListening) {
      _speechToText.cancel();
      print('SpeechService - canceled active listening in dispose');
    }
  }
}
