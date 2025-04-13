// lib/presentation/screens/speaker_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/speech_provider.dart';
import '../providers/translation_provider.dart';
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
  String _selectedAudienceLanguage =
      'Spanish'; // Default different language for demo
  bool _isInitialized = false;
  bool _isLoading = true;
  String _translatedPreview = ''; // Preview of translation

  @override
  void initState() {
    super.initState();
    print('SpeakerScreen - initState called');

    // Always start with loading state
    setState(() {
      _isLoading = true;
    });

    // Use separate microtasks for initialization to prevent UI freezing
    _initializeAll();
  }

  // Initialize everything
  Future<void> _initializeAll() async {
    print('SpeakerScreen - initializing all services');

    try {
      // First handle session creation
      await _initializeSession();

      // Then initialize speech recognition
      await _initializeSpeech();

      // Finally, initialize translation
      await _initializeTranslation();

      // Update UI state when all initialization is complete
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        print('SpeakerScreen - completed all initialization');
      }
    } catch (e) {
      print('SpeakerScreen - initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        sessionProvider.createSession(
          _languageCodes[_selectedLanguage] ?? 'en-US',
        );
      } else {
        print('SpeakerScreen - session already active');
      }
    });
  }

  Future<bool> _requestPermissions() async {
    print('SpeakerScreen - requesting permissions');

    // Request microphone permission
    PermissionStatus micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      print('SpeakerScreen - microphone permission denied');
      return false;
    }

    // On iOS, also need speech recognition permission
    if (Platform.isIOS) {
      PermissionStatus speechStatus = await Permission.speech.request();
      if (speechStatus != PermissionStatus.granted) {
        print('SpeakerScreen - speech recognition permission denied');
        return false;
      }
    }

    print('SpeakerScreen - all permissions granted');
    return true;
  }

  // Initialize speech in a separate method
  Future<void> _initializeSpeech() async {
    print('SpeakerScreen - initializing speech');

    try {
      // First check permissions
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition requires microphone permission',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

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

  // Initialize translation in a separate method
  Future<void> _initializeTranslation() async {
    print('SpeakerScreen - initializing translation');

    try {
      final translationProvider = Provider.of<TranslationProvider>(
        context,
        listen: false,
      );

      // Initialize translation services
      final initialized = await translationProvider.initialize();
      if (!initialized) {
        print('SpeakerScreen - translation initialization failed');

        // Show a snackbar if initialization fails but allow the user to continue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Translation services initialization failed: ${translationProvider.error}',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('SpeakerScreen - translation initialization successful');

        // Set initial languages
        translationProvider.setSpeakerLanguage(
          _languageCodes[_selectedLanguage] ?? 'en-US',
        );
        translationProvider.setAudienceLanguage(
          _languageCodes[_selectedAudienceLanguage] ?? 'es-ES',
        );

        // Connect to WebSocket session
        final sessionProvider = Provider.of<SessionProvider>(
          context,
          listen: false,
        );
        final sessionCode = sessionProvider.currentSession?.sessionCode;
        if (sessionCode != null) {
          print(
            'SpeakerScreen - connecting to WebSocket session: $sessionCode',
          );
          translationProvider.connectToSession(
            sessionCode: sessionCode,
            role: 'speaker',
          );
        }
      }
    } catch (e) {
      print('SpeakerScreen - error initializing translation: $e');

      // Show error but allow the user to continue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing translation: $e'),
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
    final translationProvider = Provider.of<TranslationProvider>(context);

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
              // Disconnect from WebSocket
              translationProvider.disconnect();
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
                      Text('Initializing services...'),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          translationProvider.isConnected
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    translationProvider.isConnected
                                        ? 'Session Active'
                                        : 'Session Inactive',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          translationProvider.isConnected
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Language selections in a row
                      Row(
                        children: [
                          // Speaker language
                          Expanded(
                            child: DropdownButtonFormField<String>(
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

                                  print(
                                    'SpeakerScreen - language changed to $value',
                                  );
                                  final languageCode =
                                      _languageCodes[value] ?? 'en-US';
                                  speechProvider.setLanguage(languageCode);
                                  translationProvider.setSpeakerLanguage(
                                    languageCode,
                                  );

                                  // If we have text, update the translation preview
                                  if (speechProvider
                                      .recognizedText
                                      .isNotEmpty) {
                                    _updateTranslationPreview(
                                      speechProvider.recognizedText,
                                    );
                                  }
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Audience language
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Audience Language',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedAudienceLanguage,
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
                                    _selectedAudienceLanguage = value;
                                  });

                                  print(
                                    'SpeakerScreen - audience language changed to $value',
                                  );
                                  final languageCode =
                                      _languageCodes[value] ?? 'en-US';
                                  translationProvider.setAudienceLanguage(
                                    languageCode,
                                  );

                                  // If we have text, update the translation preview
                                  if (speechProvider
                                      .recognizedText
                                      .isNotEmpty) {
                                    _updateTranslationPreview(
                                      speechProvider.recognizedText,
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Status indicators row
                      Row(
                        children: [
                          // Speech status
                          if (speechProvider.isInitializing ||
                              speechProvider.isListening)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                backgroundColor: Colors.blue.shade100,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      speechProvider.isInitializing
                                          ? 'Initializing...'
                                          : 'Listening...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Translation status
                          if (translationProvider.isTranslating)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                backgroundColor: Colors.purple.shade100,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Translating...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // TTS status
                          if (translationProvider.isSpeaking)
                            Chip(
                              backgroundColor: Colors.green.shade100,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Speaking...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Error display if any
                      if (speechProvider.error.isNotEmpty ||
                          translationProvider.error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (speechProvider.error.isNotEmpty)
                                Text(
                                  'Speech Error: ${speechProvider.error}',
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              if (translationProvider.error.isNotEmpty)
                                Text(
                                  'Translation Error: ${translationProvider.error}',
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                            ],
                          ),
                        ),

                      // Recognized text and translation display
                      Expanded(
                        child: Row(
                          children: [
                            // Original text
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Original ($_selectedLanguage)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (speechProvider.isListening)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade800,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Listening',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          speechProvider.recognizedText.isEmpty
                                              ? 'Your speech will appear here...'
                                              : speechProvider.recognizedText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                speechProvider
                                                        .recognizedText
                                                        .isEmpty
                                                    ? Colors.grey
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Translated text (preview only for speaker)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade50,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Translation ($_selectedAudienceLanguage)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (translationProvider.isTranslating)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            Colors
                                                                .purple
                                                                .shade800,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Translating',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.purple.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          _translatedPreview.isEmpty
                                              ? 'Translation will appear here...'
                                              : _translatedPreview,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                _translatedPreview.isEmpty
                                                    ? Colors.grey
                                                    : Colors.black,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Clear button
                          ElevatedButton.icon(
                            onPressed: () {
                              print('SpeakerScreen - clear text pressed');
                              speechProvider.clearText();
                              setState(() {
                                _translatedPreview = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          // Microphone button
                          FloatingActionButton(
                            onPressed:
                                speechProvider.isListening
                                    ? () async {
                                      print(
                                        'SpeakerScreen - stop listening pressed',
                                      );
                                      await speechProvider.stopListening();

                                      // Auto-translate when speech ends
                                      if (speechProvider
                                          .recognizedText
                                          .isNotEmpty) {
                                        _updateTranslationPreview(
                                          speechProvider.recognizedText,
                                        );
                                      }
                                    }
                                    : () {
                                      print(
                                        'SpeakerScreen - start listening pressed',
                                      );
                                      speechProvider.startListening();
                                    },
                            backgroundColor:
                                speechProvider.isListening
                                    ? Colors.red
                                    : Colors.blue,
                            child: Icon(
                              speechProvider.isListening
                                  ? Icons.stop
                                  : Icons.mic,
                              size: 32,
                            ),
                          ),

                          // Send button - now enabled
                          ElevatedButton.icon(
                            onPressed:
                                speechProvider.recognizedText.isEmpty ||
                                        translationProvider.isTranslating
                                    ? null // Disabled if no text or already translating
                                    : () async {
                                      print(
                                        'SpeakerScreen - send translation pressed',
                                      );
                                      if (speechProvider
                                          .recognizedText
                                          .isNotEmpty) {
                                        // Use the translation provider to process the text
                                        // this will translate and send via WebSocket
                                        await translationProvider.translateText(
                                          speechProvider.recognizedText,
                                        );

                                        // Show a success indicator
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Translation sent to audience',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            icon: const Icon(Icons.send),
                            label: const Text('Send'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.withOpacity(
                                0.3,
                              ),
                              disabledForegroundColor: Colors.grey.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  // Helper method to update translation preview
  Future<void> _updateTranslationPreview(String text) async {
    print('SpeakerScreen - updating translation preview');
    if (text.isEmpty) return;

    try {
      final translationProvider = Provider.of<TranslationProvider>(
        context,
        listen: false,
      );

      final translated = await translationProvider.translateText(text);

      // Only update state if still mounted
      if (mounted) {
        setState(() {
          _translatedPreview = translated;
        });
      }
    } catch (e) {
      print('SpeakerScreen - translation preview error: $e');

      // Show error in UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation preview error: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Ensure any active processes are stopped before disposing
    print('SpeakerScreen - dispose called');
    super.dispose();
  }
}
