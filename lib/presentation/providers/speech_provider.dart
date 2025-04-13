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
    final initialized = await _speechService.initialize();
    notifyListeners();
    return initialized;
  }

  // Set the selected language
  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    notifyListeners();
  }

  // Start speech recognition
  Future<void> startListening() async {
    if (!_speechService.isAvailable) {
      await initialize();
    }

    _isListening = true;
    notifyListeners();

    await _speechService.startListening(
      onResult: (text) {
        _recognizedText = text;
        notifyListeners();
      },
      selectedLocaleId: _selectedLanguage,
    );
  }

  // Stop speech recognition
  Future<void> stopListening() async {
    await _speechService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  // Clear the recognized text
  void clearText() {
    _recognizedText = '';
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
