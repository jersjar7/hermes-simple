// lib/presentation/screens/speaker_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hermes_app/presentation/widgets/error_message_widget.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/speech_provider.dart';
import '../widgets/speech_control_panel.dart';
import '../../core/constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';

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

    // Initialize with loading state
    _isLoading = true;
    _isInitialized = false;

    // Use a single initialization flow with better state management
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('SpeakerScreen - starting initialization sequence');

    try {
      // Step 1: Request permissions first
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('SpeakerScreen - permissions denied, stopping initialization');
        if (mounted) {
          setState(() {
            _isLoading = false;
            // We won't mark as initialized because permissions are missing
          });
        }
        return;
      }

      // Step 2: Initialize session (always succeeds in current implementation)
      await _initializeSession();

      // Step 3: Initialize speech recognition
      final speechProvider = Provider.of<SpeechProvider>(
        context,
        listen: false,
      );
      final speechInitialized = await speechProvider.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = speechInitialized;
          _isLoading = false;
        });

        print(
          'SpeakerScreen - initialization complete: ${_isInitialized ? 'success' : 'failed'}',
        );

        // Show success/failure message if needed
        if (!_isInitialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition initialization failed. '
                'Some features may not work.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('SpeakerScreen - error during initialization: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during initialization: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Initialize session in a separate method
  Future<void> _initializeSession() async {
    print('SpeakerScreen - initializing session');

    // Use Future.microtask to avoid calling setState during build
    return Future.microtask(() {
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
    });
  }

  Future<bool> _requestPermissions() async {
    print('SpeakerScreen - requesting permissions');

    // Check if permissions are already granted
    bool micGranted = await Permission.microphone.isGranted;
    bool speechGranted = true;
    if (Platform.isIOS) {
      speechGranted = await Permission.speech.isGranted;
    }

    if (micGranted && speechGranted) {
      print('SpeakerScreen - permissions already granted');
      return true;
    }

    // Request microphone permission if not granted
    if (!micGranted) {
      PermissionStatus micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        print('SpeakerScreen - microphone permission denied');

        // Show persistent permission request explanation
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Microphone Permission Required'),
                content: const Text(
                  'Hermes needs microphone access to convert your speech to text. '
                  'Please grant this permission in your device settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Return to home screen
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        }
        return false;
      }
    }

    // On iOS, also need speech recognition permission
    if (Platform.isIOS && !speechGranted) {
      PermissionStatus speechStatus = await Permission.speech.request();
      if (speechStatus != PermissionStatus.granted) {
        print('SpeakerScreen - speech recognition permission denied');

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Speech Recognition Permission Required'),
                content: const Text(
                  'Hermes needs speech recognition permission to convert your speech to text. '
                  'Please grant this permission in your device settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Return to home screen
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        }
        return false;
      }
    }

    print('SpeakerScreen - all permissions granted');
    return true;
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

                      // Error display with improved widget
                      if (speechProvider.hasError)
                        ErrorMessageWidget(
                          errorMessage: speechProvider.errorMessage,
                          onDismiss: () {
                            speechProvider.clearError();
                          },
                          onRetry:
                              speechProvider.isInitialized
                                  ? null
                                  : () {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    speechProvider.initialize().then((_) {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    });
                                  },
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
