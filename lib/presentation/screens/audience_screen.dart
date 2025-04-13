// lib/presentation/screens/audience_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/translation_provider.dart';
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
    print('AudienceScreen - initState called');

    // Start with loading state
    setState(() {
      _isLoading = true;
    });

    // Initialize translation service
    _initializeTranslation();
  }

  // Initialize translation in a separate method
  Future<void> _initializeTranslation() async {
    print('AudienceScreen - initializing translation');

    try {
      final translationProvider = Provider.of<TranslationProvider>(
        context,
        listen: false,
      );

      // Initialize translation services
      final initialized = await translationProvider.initialize();
      if (!initialized) {
        print('AudienceScreen - translation initialization failed');

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
        print('AudienceScreen - translation initialization successful');

        // Set initial audience language
        translationProvider.setAudienceLanguage(
          _languageCodes[_selectedLanguage] ?? 'en-US',
        );
      }

      // Update UI state
      if (mounted) {
        setState(() {
          _isInitialized = initialized;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AudienceScreen - error initializing translation: $e');

      // Show error but allow the user to continue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing translation: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void onSessionCodeSubmit(BuildContext context, String code) async {
    print('AudienceScreen - session code submitted: $code');

    // Get providers
    final sessionProvider = Provider.of<SessionProvider>(
      context,
      listen: false,
    );
    final translationProvider = Provider.of<TranslationProvider>(
      context,
      listen: false,
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Join session
      final success = sessionProvider.joinSession(code);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (!success) {
        print('AudienceScreen - invalid session code');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid session code. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('AudienceScreen - successfully joined session');

        // Connect to WebSocket session
        if (context.mounted) {
          final connected = await translationProvider.connectToSession(
            sessionCode: code,
            role: 'audience',
          );

          if (!connected && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Connected to session, but WebSocket connection failed: ${translationProvider.error}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (context.mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully joined translation session!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('AudienceScreen - error joining session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'AudienceScreen - build method called, initialized: $_isInitialized, loading: $_isLoading',
    );
    final sessionProvider = Provider.of<SessionProvider>(context);
    final translationProvider = Provider.of<TranslationProvider>(context);

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
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing translation services...'),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!sessionProvider.isSessionActive) ...[
                        // Session joining UI
                        const SizedBox(height: 20),
                        const Text(
                          'Join a Hermes Translation Session',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                          onSubmit:
                              (code) => onSessionCodeSubmit(context, code),
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
                                          ? 'Live'
                                          : 'Disconnected',
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
                              print(
                                'AudienceScreen - language changed to $value',
                              );
                              setState(() {
                                _selectedLanguage = value;
                              });

                              // Update translation provider language
                              final languageCode =
                                  _languageCodes[value] ?? 'en-US';
                              translationProvider.setAudienceLanguage(
                                languageCode,
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Status indicators row
                        if (translationProvider.isTranslating ||
                            translationProvider.isSpeaking)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
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
                          ),

                        // Error display
                        if (translationProvider.error.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Error: ${translationProvider.error}',
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),

                        // Translation display
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Information label
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Translation ($_selectedLanguage)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              // Original text (in small box)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Original:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      translationProvider
                                              .lastOriginalText
                                              .isEmpty
                                          ? 'Waiting for speaker...'
                                          : translationProvider
                                              .lastOriginalText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            translationProvider
                                                    .lastOriginalText
                                                    .isEmpty
                                                ? Colors.grey
                                                : Colors.black,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Translated text (main container)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.blue.shade50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Translation:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            translationProvider
                                                    .lastTranslatedText
                                                    .isEmpty
                                                ? 'Translated speech will appear here...'
                                                : translationProvider
                                                    .lastTranslatedText,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color:
                                                  translationProvider
                                                          .lastTranslatedText
                                                          .isEmpty
                                                      ? Colors.grey
                                                      : Colors.black,
                                              fontWeight: FontWeight.w500,
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

                        // Control buttons at the bottom
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Refresh connection button
                              ElevatedButton.icon(
                                onPressed:
                                    !translationProvider.isConnected
                                        ? () async {
                                          print(
                                            'AudienceScreen - reconnect button pressed',
                                          );
                                          final sessionCode =
                                              sessionProvider.joinedSessionCode;
                                          if (sessionCode != null) {
                                            final connected =
                                                await translationProvider
                                                    .connectToSession(
                                                      sessionCode: sessionCode,
                                                      role: 'audience',
                                                    );

                                            if (!connected && mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Connection failed: ${translationProvider.error}',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        : null,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reconnect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey
                                      .withValues(alpha: 0.3),
                                  disabledForegroundColor: Colors.grey
                                      .withValues(alpha: 0.7),
                                ),
                              ),

                              // Speak latest translation button
                              ElevatedButton.icon(
                                onPressed:
                                    translationProvider
                                                .lastTranslatedText
                                                .isNotEmpty &&
                                            !translationProvider.isSpeaking
                                        ? () {
                                          print(
                                            'AudienceScreen - speak button pressed',
                                          );
                                          translationProvider
                                              .speakTranslatedText(
                                                translationProvider
                                                    .lastTranslatedText,
                                              );
                                        }
                                        : null,
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Speak'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey
                                      .withValues(alpha: 0.3),
                                  disabledForegroundColor: Colors.grey
                                      .withValues(alpha: 0.7),
                                ),
                              ),

                              // Stop speaking button
                              ElevatedButton.icon(
                                onPressed:
                                    translationProvider.isSpeaking
                                        ? () {
                                          print(
                                            'AudienceScreen - stop speaking button pressed',
                                          );
                                          translationProvider.stopSpeaking();
                                        }
                                        : null,
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey
                                      .withValues(alpha: 0.3),
                                  disabledForegroundColor: Colors.grey
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    // Add any cleanup here
    super.dispose();
  }
}
