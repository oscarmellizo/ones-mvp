import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color.fromRGBO(252, 192, 86, 1.0); // Cambia según el manual de marca
  static const Color secondaryColor = Color.fromRGBO(74, 3, 110, 1.0); // Otro color del branding
  static const Color textColor = Colors.white;

  static const TextStyle splashTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    fontFamily: 'Montserrat', // Asegúrate de tener esta fuente en pubspec.yaml
  );

  static const TextStyle appBarTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
}
