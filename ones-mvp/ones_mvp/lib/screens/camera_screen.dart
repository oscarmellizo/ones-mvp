import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ones_mvp/screens/gallery_screen.dart';
import 'package:ones_mvp/services/permissions_service.dart';

class CameraScreen extends StatefulWidget {
  final String eventCode;
  CameraScreen({required this.eventCode});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print("❌ No hay cámaras disponibles");
        return;
      }

      _controller = CameraController(_cameras[0], ResolutionPreset.medium);
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      print("✅ Cámara inicializada correctamente");
    } catch (e) {
      print("❌ Error al inicializar la cámara: $e");
    }
  }

  Future<void> capturePhoto() async {
    try {
      print("📸 Intentando capturar foto...");

      if (!(await requestPermissions())) {
        print("❌ Permiso denegado, no se puede capturar la foto.");
        return;
      }

      if (!_controller.value.isInitialized) {
        print("❌ La cámara no está inicializada.");
        return;
      }

      // 1️⃣ Capturar la foto con la cámara
      final XFile? photo = await _controller.takePicture();
      if (photo == null || photo.path.isEmpty) {
        print("❌ No se pudo capturar la foto.");
        return;
      }

      final File imageFile = File(photo.path);
      print("📸 Foto tomada con éxito en: ${photo.path}");

      // 2️⃣ Definir correctamente la ruta de almacenamiento
      final String onesFolderPath = "/storage/emulated/0/Pictures/Ones";
      final String eventFolderPath = "$onesFolderPath/${widget.eventCode}";

      // 🔹 Validar y crear carpetas correctamente
      final Directory eventDirectory = Directory(eventFolderPath);
      if (!await eventDirectory.exists()) {
        print("📁 Creando carpeta del evento en: $eventFolderPath");
        await eventDirectory.create(recursive: true);
      }

      // 3️⃣ Guardar la imagen en la carpeta del evento
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String newPath =
          "$eventFolderPath/$fileName"; // 🔹 CORRECCIÓN: NO DUPLICAR RUTAS

      await imageFile.copy(newPath);
      print("✅ Foto guardada correctamente en: $newPath");

      // 4️⃣ Mostrar confirmación en la UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Foto guardada en:\n$newPath")),
      );
    } catch (e, stacktrace) {
      print("❌ Error al capturar foto: $e");
      print(stacktrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error al guardar la foto: $e")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tomar Foto")),
      body: _isCameraInitialized
          ? Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                ElevatedButton(
                  onPressed: capturePhoto,
                  child: Text("📸 Capturar Foto"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              GalleryScreen(eventCode: widget.eventCode)),
                    );
                  },
                  child: Text("📷 Ver Galería"),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
