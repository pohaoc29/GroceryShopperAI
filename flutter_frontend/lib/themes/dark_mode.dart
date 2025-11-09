import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: Color(0xFF10B981),
  scaffoldBackgroundColor: Color(0xFF0F172A),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E293B),
    elevation: 1,
    centerTitle: false,
    iconTheme: IconThemeData(color: Color(0xFF10B981)),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF10B981),
      fontFamily: 'StackSans',
    ),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF10B981),
      fontFamily: 'StackSans',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFFE2E8F0),
      fontFamily: 'StackSansText',
    ),
  ),
);
