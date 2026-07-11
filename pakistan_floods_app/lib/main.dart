import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FloodGuardApp());
}

class FloodGuardApp extends StatelessWidget {
  const FloodGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // NDMA-inspired Whites, Blues, and Greens Color Scheme
    const prNavy = Color(0xFF1B365D); // Deep Prussian/Navy Blue
    const scForest = Color(0xFF2D6A4F); // Serious NDMA Green
    const bgLight = Color(0xFFF8FAFC); // Clean Slate White background
    const surfaceWhite = Color(0xFFFFFFFF); // Crisp surface cards

    return MaterialApp(
      title: 'FloodGuard Pakistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        primaryColor: prNavy,
        scaffoldBackgroundColor: bgLight,
        colorScheme: const ColorScheme.light(
          primary: prNavy,
          secondary: scForest,
          surface: surfaceWhite,
          error: Color(0xFFC53030), // Colorblind-accessible red
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceWhite,
          elevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: prNavy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: prNavy),
        ),
        cardTheme: const CardThemeData(
          color: surfaceWhite,
          margin: EdgeInsets.zero,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          bodyMedium: TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: prNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)), // Unified geometric corners
            ),
            minimumSize: const Size(double.infinity, 44),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF1F5F9), // Light background for inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: prNavy, width: 1.5),
          ),
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
