// lib/presentation/widgets/session_code_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/session_code_generator.dart'; // Added import

class SessionCodeInput extends StatefulWidget {
  final Function(String) onSubmit;

  const SessionCodeInput({super.key, required this.onSubmit});

  @override
  State<SessionCodeInput> createState() => _SessionCodeInputState();
}

class _SessionCodeInputState extends State<SessionCodeInput> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _errorMessage; // Added for better error feedback

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Added method to handle submission with proper logging
  void _handleSubmit() {
    print(
      'SessionCodeInput - handleSubmit called with text: "${_codeController.text}"',
    );

    if (_formKey.currentState!.validate()) {
      print('SessionCodeInput - validation passed, calling onSubmit');
      final code = _codeController.text.trim().toUpperCase();

      // Added extra validation to ensure code format is correct
      if (SessionCodeGenerator.isValidSessionCode(code)) {
        widget.onSubmit(code);
      } else {
        print('SessionCodeInput - invalid code format: $code');
        setState(() {
          _errorMessage = 'Invalid code format. Please check and try again.';
        });
      }
    } else {
      print('SessionCodeInput - validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Session Code',
              hintText: 'Enter the 6-digit code',
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: _errorMessage, // Display error message if any
            ),
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            maxLength: AppConstants.sessionCodeLength,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a session code';
              }
              if (value.length != AppConstants.sessionCodeLength) {
                return 'Code must be ${AppConstants.sessionCodeLength} characters';
              }
              // Clear any previous error messages on new validation
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            // Added onFieldSubmitted to handle keyboard "Done" button
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSubmit, // Changed to use the new method
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Join Session', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// Custom input formatter to convert text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
