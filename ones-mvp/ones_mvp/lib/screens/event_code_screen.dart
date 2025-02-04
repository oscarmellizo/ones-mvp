import 'package:flutter/material.dart';

final Map<String, String> eventCodes = {
  "E1": "/storage/emulated/0/Ones/EVENTO001",
  "E2": "/storage/emulated/0/Ones/EVENTO002",
};

class EventCodeScreen extends StatefulWidget {
  @override
  _EventCodeScreenState createState() => _EventCodeScreenState();
}

class _EventCodeScreenState extends State<EventCodeScreen> {
  final TextEditingController _controller = TextEditingController();
  String? errorMessage;

  void validateCode() {
    final code = _controller.text.trim();
    if (eventCodes.containsKey(code)) {
      Navigator.pushNamed(context, '/menu', arguments: eventCodes[code]);
    } else {
      setState(() {
        errorMessage = "Código de evento inválido";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ingresa el Código del Evento")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: "Código del evento"),
            ),
            if (errorMessage != null)
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: validateCode,
              child: Text("Ingresar"),
            ),
          ],
        ),
      ),
    );
  }
}
