import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
    );

    final arimoTextTheme = GoogleFonts.arimoTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: arimoTextTheme,
      primaryTextTheme: GoogleFonts.arimoTextTheme(base.primaryTextTheme),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: GoogleFonts.arimo(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
