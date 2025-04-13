// lib/presentation/screens/audience_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../widgets/session_code_input.dart';
import '../../core/constants/app_constants.dart';

class AudienceScreen extends StatefulWidget {
  const AudienceScreen({super.key});

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  final List<String> _languages = [
    'English (US)',
    'Spanish',
    'French',
    'German',
    'Chinese',
  ];
  String _selectedLanguage = 'English (US)';
  String _translatedText = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print('AudienceScreen - initState called');

    Future.microtask(() {
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print('AudienceScreen - build method called, initialized: $_isInitialized');
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audience Mode'),
        centerTitle: true,
        actions: [
          if (sessionProvider.isSessionActive)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                print('AudienceScreen - exit button pressed');
                sessionProvider.endSession();
                setState(() {
                  _translatedText = '';
                });
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
              if (!sessionProvider.isSessionActive) ...[
                // Session joining UI
                const SizedBox(height: 20),
                const Text(
                  'Join a Hermes Translation Session',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the session code provided by the speaker',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SessionCodeInput(
                  onSubmit: (code) {
                    print('AudienceScreen - submitted session code: $code');
                    final success = sessionProvider.joinSession(code);
                    if (!success) {
                      print('AudienceScreen - invalid session code');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Invalid session code. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      print('AudienceScreen - successfully joined session');
                    }
                  },
                ),
              ] else ...[
                // Session active UI
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Connected to Session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sessionProvider.joinedSessionCode ?? 'ERROR',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
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
                      print('AudienceScreen - language changed to $value');
                      setState(() {
                        _selectedLanguage = value;
                      });
                      // In Phase 2, this would update the translation language
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Translated text display
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _translatedText.isEmpty
                            ? 'Translated speech will appear here...'
                            : _translatedText,
                        style: TextStyle(
                          fontSize: 18,
                          color:
                              _translatedText.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
