// Avertissement : usage éducatif uniquement. Respectez les conditions
// d'utilisation des plateformes et les droits d'auteur.
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const VideoDlApp());

class VideoDlApp extends StatelessWidget {
  const VideoDlApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Video Downloader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
            brightness: Brightness.dark),
        home: const HomeScreen(),
      );
}
