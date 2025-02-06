import 'package:flutter/material.dart';
import 'package:ones_mvp/theme/theme.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String eventCode = ModalRoute.of(context)!.settings.arguments as String;

    final List<Map<String, dynamic>> menuOptions = [
      {
        "title": "Ver Galería",
        "icon": "assets/gallery_icon.png",
        "route": GalleryScreen(eventCode: eventCode),
      },
      {
        "title": "Tomar Foto",
        "icon": "assets/camera_icon.png",
        "route": CameraScreen(eventCode: eventCode),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Menú del Evento", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                  MaterialPageRoute(builder: (context) => option["route"]),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Image.asset(
                        option["icon"],
                        width: 50,
                        height: 50,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        option["title"],
                        style: TextStyle(
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
