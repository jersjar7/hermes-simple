// lib/presentation/providers/speech_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/services/speech_service.dart';

class SpeechProvider with ChangeNotifier {
  final SpeechService _speechService = SpeechService();

  String _recognizedText = '';
  bool _isListening = false;
  bool _isInitializing = false;
  bool _isInitialized = false;
  String _selectedLanguage = 'en-US'; // Default language
  String _error = ''; // Added error property

  String get recognizedText => _recognizedText;
  bool get isListening => _isListening;
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;
  String get selectedLanguage => _selectedLanguage;
  String get error => _error; // Added getter for error

  // Initialize the speech service with proper error handling
  Future<bool> initialize() async {
    print('SpeechProvider - initializing speech service');

    // Avoid duplicate initialization
    if (_isInitializing) {
      print('SpeechProvider - already initializing, waiting');
      return _isInitialized;
    }

    if (_isInitialized) {
      print('SpeechProvider - already initialized');
      return true;
    }

    _isInitializing = true;
    _error = '';
    notifyListeners();

    try {
      print('SpeechProvider - calling speech service initialize');
      final initialized = await _speechService.initialize();
      _isInitialized = initialized;
      _isInitializing = false;

      if (!initialized) {
        _error = 'Failed to initialize speech recognition';
        print('SpeechProvider - initialization failed');
      } else {
        print('SpeechProvider - initialization successful');
      }

      notifyListeners();
      return initialized;
    } catch (e) {
      print('SpeechProvider - initialization error: $e');
      _isInitialized = false;
      _isInitializing = false;
      _error = 'Error initializing speech: $e';
      notifyListeners();
      return false;
    }
  }

  // Set the selected language
  void setLanguage(String languageCode) {
    print('SpeechProvider - setting language to: $languageCode');
    _selectedLanguage = languageCode;
    notifyListeners();
  }

  // Start speech recognition with error handling
  Future<void> startListening() async {
    print('SpeechProvider - startListening called');

    // Avoid duplicate listening sessions
    if (_isListening) {
      print('SpeechProvider - already listening, skipping');
      return;
    }

    // Make sure we're initialized
    if (!_isInitialized) {
      print('SpeechProvider - not initialized, initializing first');
      final initialized = await initialize();
      if (!initialized) {
        _error = 'Could not initialize speech recognition';
        notifyListeners();
        print('SpeechProvider - initialization failed, cannot start listening');
        return;
      }
    }

    _isListening = true;
    _error = '';
    notifyListeners();
    print('SpeechProvider - listening state updated, starting recognition');

    try {
      final success = await _speechService.startListening(
        onResult: (text) {
          print('SpeechProvider - received speech result: "$text"');
          _recognizedText = text;
          notifyListeners();
        },
        selectedLocaleId: _selectedLanguage,
      );

      if (!success) {
        _isListening = false;
        _error = 'Failed to start speech recognition';
        notifyListeners();
        print('SpeechProvider - failed to start listening');
      }
    } catch (e) {
      print('SpeechProvider - error in startListening: $e');
      _isListening = false;
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  // Stop speech recognition with error handling
  Future<void> stopListening() async {
    print('SpeechProvider - stopListening called');

    if (!_isListening) {
      print('SpeechProvider - not listening, nothing to stop');
      return;
    }

    try {
      final success = await _speechService.stopListening();
      _isListening = false;

      if (!success) {
        _error = 'Failed to stop speech recognition';
        print('SpeechProvider - failed to stop listening');
      } else {
        print('SpeechProvider - listening stopped successfully');
      }

      notifyListeners();
    } catch (e) {
      print('SpeechProvider - error in stopListening: $e');
      _isListening = false;
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  // Emergency reset of the speech recognition
  Future<void> resetRecognition() async {
    print('SpeechProvider - resetRecognition called');

    try {
      if (_isListening) {
        await _speechService.cancelListening();
      }

      _isListening = false;
      _error = '';
      notifyListeners();
      print('SpeechProvider - recognition reset');
    } catch (e) {
      print('SpeechProvider - error in resetRecognition: $e');
      _isListening = false;
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  // Clear the recognized text
  void clearText() {
    print('SpeechProvider - clearText called');
    _recognizedText = '';
    _error = '';
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    print('SpeechProvider - dispose called');

    // Ensure speech service is properly cleaned up
    if (_isListening) {
      _speechService.stopListening();
      print('SpeechProvider - stopped listening during dispose');
    }

    _speechService.dispose();
    super.dispose();
  }
}
