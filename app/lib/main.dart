import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'discovery_screen.dart';

void main() {
  runApp(const SimSearchApp());
}

class SimSearchApp extends StatelessWidget {
  const SimSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimSearch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF3F3F4),
      ),
      home: const DiscoveryScreen(),
    );
  }
}
