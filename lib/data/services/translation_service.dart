// lib/data/services/translation_service.dart

import 'dart:async';
import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();
  bool _isInitialized = false;

  // Initialize the translation service
  Future<bool> initialize() async {
    print('TranslationService - initialize called');

    if (_isInitialized) {
      print('TranslationService - already initialized');
      return true;
    }

    try {
      // Add initialization logic if needed
      // For the translator package, minimal initialization is required
      _isInitialized = true;
      print('TranslationService - successfully initialized');
      return true;
    } catch (e) {
      print('TranslationService - initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Translate text from source language to target language
  Future<String> translateText({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    print('TranslationService - translateText called');
    print('TranslationService - from: $fromLanguage, to: $toLanguage');
    print('TranslationService - original text: "$text"');

    if (text.isEmpty) {
      print('TranslationService - empty text, returning empty string');
      return '';
    }

    try {
      // Convert language codes from our format to translator package format
      final from = _getTranslatorLanguageCode(fromLanguage);
      final to = _getTranslatorLanguageCode(toLanguage);

      print('TranslationService - mapped codes: from=$from, to=$to');

      // Perform the translation with a timeout to prevent hanging
      final translation = await _translator
          .translate(text, from: from, to: to)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('TranslationService - translation timed out');
              throw TimeoutException('Translation request timed out');
            },
          );

      print('TranslationService - translation result: "${translation.text}"');
      return translation.text;
    } catch (e) {
      print('TranslationService - translation error: $e');
      return 'Translation Error: $e';
    }
  }

  // Convert our language codes to translator package language codes
  String _getTranslatorLanguageCode(String languageCode) {
    // Map complex language codes to simple ones for the translator package
    final Map<String, String> codeMapping = {
      'en-US': 'en',
      'es-ES': 'es',
      'fr-FR': 'fr',
      'de-DE': 'de',
      'zh-CN': 'zh-cn',
      'English (US)': 'en',
      'Spanish': 'es',
      'French': 'fr',
      'German': 'de',
      'Chinese': 'zh-cn',
    };

    return codeMapping[languageCode] ?? languageCode;
  }

  // Check if translation service is initialized
  bool get isInitialized => _isInitialized;
}
