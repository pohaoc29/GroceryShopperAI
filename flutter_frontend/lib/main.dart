import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'themes/light_mode.dart';
import 'themes/dark_mode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroceryChat',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
