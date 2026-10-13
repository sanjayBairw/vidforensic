import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: VidForensicApp(),
    ),
  );
}

class VidForensicApp extends StatelessWidget {
  const VidForensicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VidForensic - Video Forensic Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Modern dark forensic UI by default
      home: const HomeScreen(),
    );
  }
}
