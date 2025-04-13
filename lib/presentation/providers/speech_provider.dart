// lib/presentation/providers/speech_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/services/speech_service.dart';

class SpeechProvider with ChangeNotifier {
  final SpeechService _speechService = SpeechService();

  String _recognizedText = '';
  bool _isListening = false;
  String _selectedLanguage = 'en-US'; // Default language

  String get recognizedText => _recognizedText;
  bool get isListening => _isListening;
  String get selectedLanguage => _selectedLanguage;

  // Initialize the speech service
  Future<bool> initialize() async {
    print('SpeechProvider - initializing speech service');
    final initialized = await _speechService.initialize();
    print('SpeechProvider - initialization result: $initialized');
    notifyListeners();
    return initialized;
  }

  // Set the selected language
  void setLanguage(String languageCode) {
    print('SpeechProvider - setting language to: $languageCode');
    _selectedLanguage = languageCode;
    notifyListeners();
  }

  // Start speech recognition
  Future<void> startListening() async {
    print('SpeechProvider - startListening called');

    if (!_speechService.isAvailable) {
      print('SpeechProvider - speech service not available, initializing');
      await initialize();
    }

    _isListening = true;
    notifyListeners();
    print('SpeechProvider - listening state updated, starting recognition');

    try {
      await _speechService.startListening(
        onResult: (text) {
          print(
            'SpeechProvider - received speech result: ${text.length} chars',
          );
          _recognizedText = text;
          notifyListeners();
        },
        selectedLocaleId: _selectedLanguage,
      );
    } catch (e) {
      print('SpeechProvider - error in startListening: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  // Stop speech recognition
  Future<void> stopListening() async {
    print('SpeechProvider - stopListening called');
    try {
      await _speechService.stopListening();
      _isListening = false;
      notifyListeners();
      print('SpeechProvider - listening stopped');
    } catch (e) {
      print('SpeechProvider - error in stopListening: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  // Clear the recognized text
  void clearText() {
    print('SpeechProvider - clearText called');
    _recognizedText = '';
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    print('SpeechProvider - dispose called');
    _speechService.dispose();
    super.dispose();
  }
}
