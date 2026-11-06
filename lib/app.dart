import 'package:flutter/material.dart';
import 'models/reading.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

class PicurApp extends StatefulWidget {
  const PicurApp({super.key, required this.firebaseReady});
  final bool firebaseReady;

  @override
  State<PicurApp> createState() => _PicurAppState();
}

class _PicurAppState extends State<PicurApp> {
  final DatabaseService _database = DatabaseService();
  final ValueNotifier<ThemeMode> _theme = ValueNotifier(ThemeMode.light);

  @override
  void dispose() {
    _database.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: _theme,
        builder: (_, mode, child) => MaterialApp(
          title: 'PICUR',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff147d5a)),
            scaffoldBackgroundColor: const Color(0xfff4f6f5),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff48c994),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: HomeScreen(
            database: _database,
            firebaseReady: widget.firebaseReady,
            themeMode: mode,
            onThemeChanged: (dark) =>
                _theme.value = dark ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      );
}
