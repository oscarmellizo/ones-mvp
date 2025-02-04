import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String eventCode = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text("Menú del Evento")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GalleryScreen(eventCode: eventCode)),
              );
            },
            child: Text("Ver Galería"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraScreen(eventCode: eventCode)),
              );
            },
            child: Text("Tomar Foto"),
          ),
        ],
      ),
    );
  }
}
