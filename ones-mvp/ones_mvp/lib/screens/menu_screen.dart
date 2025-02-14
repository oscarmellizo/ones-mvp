import 'package:flutter/material.dart';
import 'package:ones_mvp/theme/theme.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';

class MenuScreen extends StatelessWidget {
  final String eventCode;
  final String folderId;

  const MenuScreen({super.key, required this.eventCode, required this.folderId});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuOptions = [
      {
        "title": "Ver Galería",
        "icon": "assets/gallery_icon.png",
        "route": () => GalleryScreen(eventCode: eventCode, folderId: folderId), // 🔹 Ahora se usa correctamente una función anónima
      },
      {
        "title": "Tomar Foto",
        "icon": "assets/camera_icon.png",
        "route": () => CameraScreen(eventCode: eventCode, folderId: folderId), // 🔹 Se pasa correctamente
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú del Evento", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, // 1 botón por fila
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 3.5, // Ajusta la altura de los botones
          ),
          itemCount: menuOptions.length,
          itemBuilder: (context, index) {
            final option = menuOptions[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => option["route"]()), // 🔹 Se usa correctamente la función anónima
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        option["icon"],
                        width: 50,
                        height: 50,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        option["title"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
