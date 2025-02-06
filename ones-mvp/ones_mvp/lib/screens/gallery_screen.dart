import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ones_mvp/services/google_drive_service.dart';
import 'package:ones_mvp/theme/theme.dart';

class GalleryScreen extends StatefulWidget {
  final String eventCode;
  const GalleryScreen({super.key, required this.eventCode});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> localPhotos = [];
  List<File> drivePhotos = [];
  Set<String> selectedPhotos = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // 🔄 Cargar fotos locales y de Drive
  Future<void> _loadPhotos() async {
    await _loadLocalPhotos();
    await _loadDrivePhotos();
  }

  // 📂 Cargar fotos locales
  Future<void> _loadLocalPhotos() async {
    try {
      final String eventFolderPath = "/storage/emulated/0/Pictures/Ones/${widget.eventCode}";
      final Directory eventDirectory = Directory(eventFolderPath);

      if (eventDirectory.existsSync()) {
        List<FileSystemEntity> files = eventDirectory.listSync();
        List<File> images = files
            .whereType<File>()
            .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.png'))
            .toList();

        images.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        setState(() {
          localPhotos = images;
        });

        print("✅ Se encontraron ${images.length} fotos locales.");
      } else {
        print("📁 No existe la carpeta del evento: $eventFolderPath");
      }
    } catch (e) {
      print("❌ Error cargando fotos locales: $e");
    }
  }

  // 🔄 Cargar fotos de Google Drive y guardarlas temporalmente
  Future<void> _loadDrivePhotos() async {
    try {
      GoogleDriveService driveService = GoogleDriveService();
      List<File> driveImages = await driveService.fetchImagesFromDrive();

      setState(() {
        drivePhotos = driveImages;
      });

      print("✅ ${driveImages.length} imágenes cargadas desde Drive.");
    } catch (e) {
      print("❌ Error cargando fotos desde Google Drive: $e");
    }
  }

  void _togglePhotoSelection(String filePath) {
    setState(() {
      if (selectedPhotos.contains(filePath)) {
        selectedPhotos.remove(filePath);
      } else {
        selectedPhotos.add(filePath);
      }
    });
  }

  Future<void> _uploadSelectedPhotos() async {
    if (selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("📌 No has seleccionado ninguna foto."),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      return;
    }

    for (String filePath in selectedPhotos) {
      File file = File(filePath);
      if (await file.exists()) {
        GoogleDriveService driveService = GoogleDriveService();
        String? fileId = await driveService.uploadFileToDrive(file);
        if (fileId != null) {
          print("✅ Foto subida con éxito: $filePath");
        } else {
          print("❌ Error al subir la foto: $filePath");
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Fotos subidas con éxito."),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    setState(() {
      selectedPhotos.clear();
    });

    _loadDrivePhotos();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> allImages = [];

    // Agregar imágenes locales
    allImages.addAll(localPhotos.map((file) {
      String filePath = file.path;
      bool isSelected = selectedPhotos.contains(filePath);

      return GestureDetector(
        onTap: () => _togglePhotoSelection(filePath),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                file,
                fit: BoxFit.cover,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: AppTheme.secondaryColor, size: 24),
              ),
          ],
        ),
      );
    }));

    // Agregar imágenes de Google Drive
    allImages.addAll(drivePhotos.map((file) {
      return Image.file(file, fit: BoxFit.cover);
    }));

    return Scaffold(
      appBar: AppBar(
        title: Text("Galería del Evento", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_upload, color: Colors.white),
            onPressed: _uploadSelectedPhotos,
          ),
        ],
      ),
      body: allImages.isEmpty
          ? Center(
              child: Text(
                "📂 No hay fotos en este evento.",
                style: AppTheme.subtitleTextStyle,
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                return allImages[index];
              },
            ),
    );
  }
}
