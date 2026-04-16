import 'package:flutter/material.dart';

class AppTheme {
  // Colors from Figma
  static const Color primary = Color(0xFF1A1A1A);      // Black buttons
  static const Color accent = Color(0xFFE8F4FD);       // Light blue bg
  static const Color categoryHome = Color(0xFF4CAF50); // Green home icon
  static const Color categorySoft = Color(0xFF2196F3); // Blue briefcase
  static const Color categoryHard = Color(0xFFF44336); // Red hardware
  static const Color categoryNet  = Color(0xFF9C27B0); // Purple network
  static const Color danger = Color(0xFFE53935);       // "Выйти" red

  static ThemeData get light => ThemeData(
    fontFamily: 'SF Pro Display', // or use GoogleFonts
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    ),
  );
}
