// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../../domain/models/user_role.dart';
import '../widgets/role_selection_card.dart';
import 'speaker_screen.dart';
import 'audience_screen.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    print('HomeScreen - initState called');

    // Reset session status when returning to home screen
    Future.microtask(() {
      final sessionProvider = Provider.of<SessionProvider>(
        context,
        listen: false,
      );
      if (sessionProvider.isSessionActive) {
        print(
          'HomeScreen - session is active, resetting on home screen return',
        );
        sessionProvider.endSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen - build method called');
    final sessionProvider = Provider.of<SessionProvider>(context);

    // This navigation logic is now in the role selection card onTap handlers
    // Instead of automatic navigation based on session state

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Welcome to Hermes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Real-time translation for live conversations',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text(
                'Choose your role:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: RoleSelectionCard(
                        title: AppConstants.speakerRole,
                        description:
                            'I want to speak and have my speech translated',
                        icon: Icons.mic,
                        onTap: () {
                          print('HomeScreen - speaker role selected');
                          sessionProvider.setUserRole(UserRole.speaker);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SpeakerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RoleSelectionCard(
                        title: AppConstants.audienceRole,
                        description: 'I want to listen to translated speech',
                        icon: Icons.headset,
                        onTap: () {
                          print('HomeScreen - audience role selected');
                          sessionProvider.setUserRole(UserRole.audience);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AudienceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
