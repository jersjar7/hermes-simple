// lib/presentation/widgets/speech_control_panel.dart

import 'package:flutter/material.dart';

class SpeechControlPanel extends StatelessWidget {
  final bool isListening;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onClearText;

  const SpeechControlPanel({
    super.key,
    required this.isListening,
    required this.onStartListening,
    required this.onStopListening,
    required this.onClearText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Clear button
        ElevatedButton.icon(
          onPressed: onClearText,
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),

        // Microphone button
        FloatingActionButton(
          onPressed: isListening ? onStopListening : onStartListening,
          backgroundColor: isListening ? Colors.red : Colors.blue,
          child: Icon(isListening ? Icons.stop : Icons.mic, size: 32),
        ),

        // Placeholder for future send button (Phase 2)
        ElevatedButton.icon(
          onPressed: null, // Disabled in Phase 1
          icon: const Icon(Icons.send),
          label: const Text('Send'),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            disabledForegroundColor: Colors.grey.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
