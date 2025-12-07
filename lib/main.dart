import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:easy_localization/easy_localization.dart';
import 'home_page.dart';
import 'theme/app_themes.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await EasyLocalization.ensureInitialized();
  await PreferencesService.initialize();
  
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('es'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('es'),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeOption _currentTheme;
  StreamSubscription<ThemeOption>? _themeSubscription;

  @override
  void initState() {
    super.initState();
    _currentTheme = PreferencesService.getSelectedTheme();
    _themeSubscription = PreferencesService.themeStream.listen((theme) {
      if (mounted) {
        setState(() => _currentTheme = theme);
      }
    });
  }

  @override
  void dispose() {
    _themeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoachUp',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppThemes.getTheme(_currentTheme),
      home: const HomePage(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            " Error al conectar con Firebase:\n$error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
