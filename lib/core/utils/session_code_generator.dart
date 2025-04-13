// lib/core/utils/session_code_generator.dart

import 'dart:math';
import '../../core/constants/app_constants.dart';

class SessionCodeGenerator {
  static final Random _random = Random();

  // Generate a random session code
  static String generateSessionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789';
    final codeBuffer = StringBuffer();

    for (var i = 0; i < AppConstants.sessionCodeLength; i++) {
      codeBuffer.write(chars[_random.nextInt(chars.length)]);
    }

    return codeBuffer.toString();
  }

  // Validate a session code
  static bool isValidSessionCode(String code) {
    if (code.length != AppConstants.sessionCodeLength) {
      return false;
    }

    // Simple validation for MVP - just check for correct length and format
    final validCodePattern = RegExp(r'^[A-Z0-9]+$');
    return validCodePattern.hasMatch(code);
  }
}
