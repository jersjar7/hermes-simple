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

  final Map<String, String> _languageCodes = {
    'English (US)': 'en-US',
    'Spanish': 'es-ES',
    'French': 'fr-FR',
    'German': 'de-DE',
    'Chinese': 'zh-CN',
  };

  String _selectedLanguage = 'English (US)';
  bool _isInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('SpeakerScreen - initState called');

    // Always start with loading state
    setState(() {
      _isLoading = true;
    });

    // Use separate microtasks for initialization to prevent UI freezing
    // First handle session creation
    _initializeSession()
        .then((_) {
          // Then once session is done, initialize speech in a separate task
          return _initializeSpeech();
        })
        .then((_) {
          // Finally update UI state when all initialization is complete
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _isLoading = false;
            });
            print('SpeakerScreen - completed all initialization');
          }
        });
  }

  // Initialize session in a separate method
  Future<void> _initializeSession() async {
    print('SpeakerScreen - initializing session');
    final sessionProvider = Provider.of<SessionProvider>(
      context,
      listen: false,
    );

    if (!sessionProvider.isSessionActive) {
      print('SpeakerScreen - creating new session');
      sessionProvider.createSession('en-US');
    } else {
      print('SpeakerScreen - session already active');
    }
  }

  // Initialize speech in a separate method
  Future<void> _initializeSpeech() async {
    print('SpeakerScreen - initializing speech');
    try {
      final speechProvider = Provider.of<SpeechProvider>(
        context,
        listen: false,
      );

      // Initialize speech recognition and handle result
      final initialized = await speechProvider.initialize();
      if (!initialized) {
        print('SpeakerScreen - speech initialization failed');

        // Show a snackbar if initialization fails but allow the user to continue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition initialization failed. Some features may not work.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('SpeakerScreen - speech initialization successful');
      }
    } catch (e) {
      print('SpeakerScreen - error initializing speech: $e');

      // Show error but allow the user to continue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing speech: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'SpeakerScreen - build method called, initialized: $_isInitialized, loading: $_isLoading',
    );
    final sessionProvider = Provider.of<SessionProvider>(context);
    final speechProvider = Provider.of<SpeechProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker Mode'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              print('SpeakerScreen - exit button pressed');
              // Stop listening if active before exiting
              if (speechProvider.isListening) {
                speechProvider.stopListening();
              }
              sessionProvider.endSession();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                // Show loading indicator while initializing
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing speech recognition...'),
                    ],
                  ),
                )
                : Padding(
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
                                sessionProvider.currentSession?.sessionCode ??
                                    'Loading...',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Share this code with your audience',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                            setState(() {
                              _selectedLanguage = value;
                            });

                            print('SpeakerScreen - language changed to $value');
                            final languageCode =
                                _languageCodes[value] ?? 'en-US';
                            speechProvider.setLanguage(languageCode);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // Speech status indicator
                      if (speechProvider.isInitializing)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Initializing speech recognition...',
                              style: TextStyle(
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),

                      // Error display if any
                      if (speechProvider.error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Error: ${speechProvider.error}',
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),

                      // Recognized text display
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              // Actual text content
                              SingleChildScrollView(
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

                              // Listening indicator overlay
                              if (speechProvider.isListening)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Listening...',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Speech controls
                      SpeechControlPanel(
                        isListening: speechProvider.isListening,
                        onStartListening: () {
                          print('SpeakerScreen - start listening pressed');
                          speechProvider.startListening();
                        },
                        onStopListening: () {
                          print('SpeakerScreen - stop listening pressed');
                          speechProvider.stopListening();
                        },
                        onClearText: () {
                          print('SpeakerScreen - clear text pressed');
                          speechProvider.clearText();
                        },
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
