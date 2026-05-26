import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/get_started_screen.dart';
import 'views/main_navigation.dart';
import 'core/services/auth_service.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initAudioService();

  runApp(const MyApp());
}

/// Initializes audio_service with a safety timeout.
/// If it fails for any reason, the app still launches normally
/// (music plays in-app, but system notifications won't show).
Future<void> _initAudioService() async {
  try {
    // Request notification permission for Android 13+
    await Permission.notification.request();

    final handler = await AudioService.init(
      builder: () => PulseAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.pulse.music.channel',
        androidNotificationChannelName: 'Pulse Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/launcher_icon',
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('AudioService.init timed out after 10s'),
    );

    AudioPlayerService().initHandler(handler);
    debugPrint('[Pulse] AudioService initialized successfully');
  } catch (e) {
    debugPrint('[Pulse] AudioService init failed: $e — falling back to direct playback');
    // Create a standalone handler so the app still works without system notifications
    AudioPlayerService().initHandler(PulseAudioHandler());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          // While checking token, show a simple black screen or splash
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(backgroundColor: Colors.black);
          }

          if (snapshot.data == true) {
            return const MainNavigation();
          } else {
            return const GetStartedScreen();
          }
        },
      ),
    );
  }
}
