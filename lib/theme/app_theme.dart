import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
    );

    return base.copyWith(
      textTheme: base.textTheme,
      primaryTextTheme: base.primaryTextTheme,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
