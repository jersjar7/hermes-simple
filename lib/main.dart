// lib/main.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/speech_provider.dart';
import 'presentation/providers/session_provider.dart';
import 'presentation/screens/home_screen.dart';

// Error observer to log errors
class LoggingErrorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigator - pushed route: ${route.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigator - popped route: ${route.settings.name}');
    super.didPop(route, previousRoute);
  }
}

void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Async error: $error');
    print('Stack trace: $stack');
    return true;
  };

  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  print('App starting...');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MyApp - build method called');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            print('Creating SpeechProvider');
            return SpeechProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print('Creating SessionProvider');
            return SessionProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Hermes',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [LoggingErrorObserver()],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        builder: (context, child) {
          // Add error handling for the entire application
          ErrorWidget.builder = (FlutterErrorDetails details) {
            print('ErrorWidget.builder: ${details.exception}');
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'An error occurred',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.exception.toString(),
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          };

          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
