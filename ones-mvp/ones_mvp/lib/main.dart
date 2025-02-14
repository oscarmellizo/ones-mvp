import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔹 Asegura la inicialización de Flutter antes de Firebase
  await Firebase.initializeApp(); // 🔹 Inicializa Firebase antes de correr la app
  runApp(const OnesApp());
}

class OnesApp extends StatelessWidget {
  const OnesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ones',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
      },
    );
  }
}
