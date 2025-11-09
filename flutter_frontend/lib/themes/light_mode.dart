import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: kPrimary,
  scaffoldBackgroundColor: kBgLight,
  appBarTheme: AppBarTheme(
    backgroundColor: kBgWhite,
    elevation: 1,
    centerTitle: false,
    iconTheme: IconThemeData(color: kPrimary),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: kPrimary,
      fontFamily: 'StackSans',
    ),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kPrimary,
      fontFamily: 'StackSans',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: kTextDark,
      fontFamily: 'StackSansText',
    ),
  ),
);
