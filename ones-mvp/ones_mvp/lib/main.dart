import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/event_code_screen.dart';
import 'screens/menu_screen.dart';
//import 'screens/gallery_screen.dart';

void main() {
  runApp(OnesApp());
}

class OnesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ones',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/event_code': (context) => EventCodeScreen(),
        '/menu': (context) => MenuScreen(),
        //'/gallery': (context) => GalleryScreen(),
      },
    );
  }
}
