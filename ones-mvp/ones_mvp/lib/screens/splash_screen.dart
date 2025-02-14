import 'package:flutter/material.dart';
import 'package:ones_mvp/screens/login_screen.dart';
import 'dart:async';
import 'package:ones_mvp/theme/theme.dart'; // Importa el tema de Ones

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Usa el color principal del manual de marca
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo-app.png', // Asegúrate de tener el logo en assets
              height: 150,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
