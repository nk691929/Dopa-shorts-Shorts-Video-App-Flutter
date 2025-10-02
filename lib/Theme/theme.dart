import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.deepPurple, // Primary color for buttons, app bar, etc.
    secondary: Colors.deepPurpleAccent.shade400, // Accent color
    tertiary: Colors.deepPurple.shade100, 
    background: Colors.white,
    surface: Colors.grey.shade100,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: Colors.black,
    onSurface: Colors.black,
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
   primary: Colors.deepPurple,
    secondary: Colors.deepPurpleAccent.shade400,
    tertiary: Colors.deepPurple.shade900, 
    background: Colors.black,
    surface: Colors.grey.shade900,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.white,
    onSurface: Colors.white,
  ),
);