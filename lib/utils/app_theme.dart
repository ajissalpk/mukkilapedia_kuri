import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData premiumTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFFD700), // Gold
    scaffoldBackgroundColor: const Color(0xFF121212), // Very Dark Grey
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD700), // Gold
      secondary: Color(0xFFD4AF37), // Metallic Gold
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black, // Dark text on Gold
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFEEEEEE),
      displayColor: const Color(0xFFFFD700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFFFD700)),
      titleTextStyle: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        elevation: 5,
        shadowColor: const Color(0xFFD4AF37),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFFD700),
      foregroundColor: Colors.black,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFFD700), width: 1),
      ),
    ),

  );
}
