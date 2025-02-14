import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ones_mvp/screens/event_code_screen.dart';
import 'package:ones_mvp/theme/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // El usuario canceló el login

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("❌ Error al autenticar: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo-app.png', width: 200), // Logo de Ones
            const SizedBox(height: 20),
            const Text("Bienvenido a Ones",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                final user = await signInWithGoogle();
                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => EventCodeScreen(user: user.user!)),
                  );
                }
              },
              icon: Image.asset('assets/google_logo.png', width: 24), // Logo de Google
              label: const Text("Iniciar sesión con Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
