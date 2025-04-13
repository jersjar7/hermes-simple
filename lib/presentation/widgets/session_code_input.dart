// lib/presentation/widgets/session_code_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class SessionCodeInput extends StatefulWidget {
  final Function(String) onSubmit;

  const SessionCodeInput({super.key, required this.onSubmit});

  @override
  State<SessionCodeInput> createState() => _SessionCodeInputState();
}

class _SessionCodeInputState extends State<SessionCodeInput> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Session Code',
              hintText: 'Enter the 6-digit code',
              border: OutlineInputBorder(),
              counterText: '',
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
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit(_codeController.text);
              }
            },
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
