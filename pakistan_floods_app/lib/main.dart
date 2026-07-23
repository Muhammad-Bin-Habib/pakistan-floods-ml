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
    const prGreen = Color(0xFF16A34A);
    const bgWhite = Color(0xFFF8FAFC);
    const surfaceWhite = Color(0xFFFFFFFF);
    const errorColor = Color(0xFFEF4444);

    return MaterialApp(
      title: 'FloodGuard Pakistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter',
        primaryColor: prGreen,
        scaffoldBackgroundColor: bgWhite,
        colorScheme: const ColorScheme.light(
          primary: prGreen,
          onPrimary: Colors.white,
          secondary: Color(0xFF2563EB),
          surface: surfaceWhite,
          onSurface: Color(0xFF111827),
          error: errorColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFF111827)),
        ),
        cardTheme: CardThemeData(
          color: surfaceWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: prGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ).copyWith(
            elevation: WidgetStateProperty.resolveWith<double>((states) {
              if (states.contains(WidgetState.hovered)) return 2;
              return 0;
            }),
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.pressed)) return const Color(0xFF15803D);
              if (states.contains(WidgetState.hovered)) return const Color(0xFF15803D);
              return prGreen;
            }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            foregroundColor: const Color(0xFF111827),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceWhite,
          hoverColor: surfaceWhite,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: prGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: errorColor, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
      ),
      home: const SplashScreen(),
    );
  }
}
