import 'package:flutter/material.dart';
import 'package:ones_mvp/screens/menu_screen.dart';
import 'package:ones_mvp/theme/theme.dart';

// Definir eventos con su código, imagen y folderId de Google Drive
final List<Map<String, String>> eventList = [
  {
    "name": "Cumpleaños",
    "path": "/storage/emulated/0/Ones/EVENTO001",
    "image": "assets/birthday.png",
    "folderId": "1FO6kJoqwhaI1vwgg5cv8hy2d4z4sLerZ"
  },
  {
    "name": "Fútbol",
    "path": "/storage/emulated/0/Ones/EVENTO002",
    "image": "assets/soccer.png",
    "folderId": "1eWVtBpoovhtSzXEPHpz-LDcqEWObLbk6"
  },
  {
    "name": "Boda",
    "path": "/storage/emulated/0/Ones/EVENTO003",
    "image": "assets/wedding.png",
    "folderId": "1sfk148oGdwV7M7W0OEKi5ykI3G2vEYck"
  },
  {
    "name": "Concierto",
    "path": "/storage/emulated/0/Ones/EVENTO004",
    "image": "assets/concert.png",
    "folderId": "10hC5y2SnREN5v2wSGIInKHF7i-FqN99x"
  },
];

class EventCodeScreen extends StatelessWidget {
  const EventCodeScreen({super.key});

  void navigateToEvent(BuildContext context, String eventPath, String folderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(eventCode: eventPath, folderId: folderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona un Evento", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 eventos por fila
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2, // Ajusta la proporción de los botones
          ),
          itemCount: eventList.length,
          itemBuilder: (context, index) {
            final event = eventList[index];
            return GestureDetector(
              onTap: () => navigateToEvent(context, event["path"]!, event["folderId"]!),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          event["image"]!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        event["name"]!,
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
