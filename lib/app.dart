import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class PicurApp extends StatefulWidget {
  const PicurApp({super.key, this.firebaseReady = false});
  final bool firebaseReady;

  @override
  State<PicurApp> createState() => _PicurAppState();
}

class _PicurAppState extends State<PicurApp> {
  ThemeMode mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PICUR Monitor',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff147d5a)),
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
          themeMode: mode,
          onThemeChanged: (dark) => setState(() => mode = dark ? ThemeMode.dark : ThemeMode.light),
        ),
      );
}
