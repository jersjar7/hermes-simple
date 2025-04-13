// lib/data/services/speech_service.dart

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants/app_constants.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    return _isInitialized;
  }

  // Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  // Check if speech recognition is currently active
  bool get isListening => _speechToText.isListening;

  // Get available languages
  Future<List<LocaleName>> getAvailableLanguages() async {
    if (!_isInitialized) await initialize();
    return _speechToText.locales();
  }

  // Start listening for speech
  Future<void> startListening({
    required Function(String text) onResult,
    String? selectedLocaleId,
  }) async {
    if (!_isInitialized) await initialize();

    await _speechToText.listen(
      onResult: (result) {
        final recognizedWords = result.recognizedWords;
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
  }

  // Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  // Dispose resources
  void dispose() {
    _speechToText.cancel();
  }
}
