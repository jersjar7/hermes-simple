// lib/presentation/screens/speaker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/speech_provider.dart';
import '../widgets/speech_control_panel.dart';
import '../../core/constants/app_constants.dart';

class SpeakerScreen extends StatefulWidget {
  const SpeakerScreen({super.key});

  @override
  State<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen> {
  final List<String> _languages = [
    'English (US)',
    'Spanish',
    'French',
    'German',
    'Chinese',
  ];
  String _selectedLanguage = 'English (US)';

  @override
  void initState() {
    super.initState();
    // Initialize the speech service
    Future.microtask(() {
      Provider.of<SpeechProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final speechProvider = Provider.of<SpeechProvider>(context);

    // Create session if not already created
    if (!sessionProvider.isSessionActive) {
      // For MVP, just use 'en-US' as default
      sessionProvider.createSession('en-US');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker Mode'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              sessionProvider.endSession();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Session code display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Your Session Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sessionProvider.currentSession?.sessionCode ?? 'ERROR',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share this code with your audience',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Language selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Your Language',
                  border: OutlineInputBorder(),
                ),
                value: _selectedLanguage,
                items:
                    _languages.map((language) {
                      return DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });

                    // Map language names to language codes (simplified for MVP)
                    final Map<String, String> languageCodes = {
                      'English (US)': 'en-US',
                      'Spanish': 'es-ES',
                      'French': 'fr-FR',
                      'German': 'de-DE',
                      'Chinese': 'zh-CN',
                    };

                    speechProvider.setLanguage(languageCodes[value] ?? 'en-US');
                  }
                },
              ),

              const SizedBox(height: 20),

              // Recognized text display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      speechProvider.recognizedText.isEmpty
                          ? 'Your speech will appear here...'
                          : speechProvider.recognizedText,
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            speechProvider.recognizedText.isEmpty
                                ? Colors.grey
                                : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Speech controls
              SpeechControlPanel(
                isListening: speechProvider.isListening,
                onStartListening: speechProvider.startListening,
                onStopListening: speechProvider.stopListening,
                onClearText: speechProvider.clearText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
