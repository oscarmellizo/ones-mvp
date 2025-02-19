import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ones_mvp/services/google_drive_service.dart';
import 'package:ones_mvp/theme/theme.dart';
import 'package:uuid/uuid.dart';

class GalleryScreen extends StatefulWidget {
  final String eventCode;
  final String folderId;

  const GalleryScreen({super.key, required this.eventCode, required this.folderId});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, Object>> allPhotos = [];
  Map<String, String> photoOwners = {}; // 📌 Mapa que asocia fotos con el nombre del usuario que la subió
  Set<String> selectedPhotos = {};
  Set<String> sharedPhotos = {}; // 📌 Fotos compartidas por el usuario local
  bool isDownloadingDrivePhotos = false;
  bool isUploadingPhotos = false;
  final Uuid _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String currentUserEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _fetchPhotoOwners();
    _loadLocalPhotos();
    _loadMissingDrivePhotos();
  }

  /// **🔐 Obtener el email del usuario autenticado**
  void _loadUserEmail() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserEmail = user.email!;
      });
    }
  }

  /// **📂 Cargar fotos locales**
  Future<void> _loadLocalPhotos() async {
    try {
      final String eventFolderPath = "/storage/emulated/0/Pictures/Ones/${widget.eventCode}";
      final Directory eventDirectory = Directory(eventFolderPath);

      if (eventDirectory.existsSync()) {
        List<FileSystemEntity> files = eventDirectory.listSync();
        List<Map<String, Object>> images = files
            .whereType<File>()
            .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.png'))
            .map((file) => {"file": file, "source": "Local"})
            .toList();

        setState(() {
          allPhotos = images;
          _sortPhotos();
        });

        print("✅ Se encontraron ${images.length} fotos locales.");
      } else {
        print("📁 No existe la carpeta del evento: $eventFolderPath");
      }
    } catch (e) {
      print("❌ Error cargando fotos locales: $e");
    }
  }

  /// **📥 Cargar fotos de Google Drive**
  Future<void> _loadMissingDrivePhotos() async {
    try {
      setState(() {
        isDownloadingDrivePhotos = true;
      });

      GoogleDriveService driveService = GoogleDriveService(widget.folderId);
      List<String> drivePhotoNames = await driveService.fetchPhotoNamesFromDrive();
      print("📂 Se encontraron ${drivePhotoNames.length} fotos en Drive.");

      Set<String> localPhotoNames = allPhotos.map((photo) => (photo["file"] as File).path.split('/').last).toSet();
      setState(() {
        sharedPhotos = localPhotoNames.intersection(drivePhotoNames.toSet());
      });

      List<String> missingPhotos = drivePhotoNames.where((name) => !localPhotoNames.contains(name)).toList();
      print("📥 ${missingPhotos.length} fotos faltan en local y se descargarán.");

      for (String photoName in missingPhotos) {
        File? downloadedPhoto = await driveService.downloadPhotoFromDrive(photoName);
        if (downloadedPhoto != null) {
          setState(() {
            allPhotos.add({"file": downloadedPhoto, "source": "Drive"});
            _sortPhotos();
          });
          print("✅ Foto $photoName descargada y agregada a la galería.");
        }
      }

      setState(() {
        isDownloadingDrivePhotos = false;
      });

    } catch (e) {
      print("❌ Error obteniendo fotos de Drive: $e");
    }
  }

  /// **📋 Consultar los dueños de las fotos desde Firestore**
  Future<void> _fetchPhotoOwners() async {
    try {
      print("✅ _fetchPhotoOwners eventCode ${widget.eventCode}");
      final querySnapshot = await _firestore.collection('photos').where('eventCode', isEqualTo: widget.eventCode.split('/').last).get();
      Map<String, String> owners = {};

      for (var doc in querySnapshot.docs) {
        final user = await _firestore.collection('users').where('email', isEqualTo: doc['userEmail']).limit(1).get();
        if (user.docs.isEmpty) {
          print("❌ Usuario no existe.");
          return;
        }
        String userName = user.docs.first.get('name');
        owners[doc['fileName']] = userName;
      }

      setState(() {
        photoOwners = owners;
        print("✅ photoOwners ${owners}");
      });

      print("✅ Se encontraron ${owners.length} fotos con dueños en Firestore.");
    } catch (e) {
      print("❌ Error al obtener dueños de fotos: $e");
    }
  }

  /// **📤 Subir fotos seleccionadas a Google Drive**
  Future<void> _uploadSelectedPhotos() async {
    if (selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📌 No has seleccionado ninguna foto."), backgroundColor: AppTheme.secondaryColor),
      );
      return;
    }

    setState(() {
      isUploadingPhotos = true;
    });

    for (String filePath in selectedPhotos) {
      File file = File(filePath);
      if (await file.exists()) {
        GoogleDriveService driveService = GoogleDriveService(widget.folderId);
        String? fileId = await driveService.uploadFileToDrive(file);
        if (fileId != null) {
          print("✅ Foto subida con éxito: $filePath");
          sharedPhotos.add(filePath);

          String photoId = _uuid.v4();

          // 📌 Guardar en Firestore
          await _firestore.collection('photos').doc(photoId).set({
            "fileName": file.path.split('/').last,
            "eventCode": widget.eventCode.split('/').last,
            "userEmail": currentUserEmail
          });

          print("📂 Foto registrada en Firestore con propietario: $currentUserEmail");
        } else {
          print("❌ Error al subir la foto: $filePath");
        }
      }
    }

    setState(() {
      isUploadingPhotos = false;
      selectedPhotos.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Fotos subidas con éxito."), backgroundColor: AppTheme.primaryColor),
    );

    _fetchPhotoOwners();
  }

  /// **🔄 Ordenar las fotos por nombre**
  void _sortPhotos() {
    setState(() {
      allPhotos.sort((a, b) {
        String nameA = (a["file"] as File).path.split('/').last;
        String nameB = (b["file"] as File).path.split('/').last;
        return nameA.compareTo(nameB);
      });
    });
  }

  void _togglePhotoSelection(String filePath, String source) {
    if (sharedPhotos.contains(filePath)) return; // 🔹 No permitir seleccionar imágenes compartidas o de Drive

    setState(() {
      if (selectedPhotos.contains(filePath)) {
        selectedPhotos.remove(filePath);
      } else {
        selectedPhotos.add(filePath);
      }
    });
  }

  /// **Verifica si hay imágenes seleccionadas que son locales y no compartidas**
  bool _hasUnsharedSelectedPhotos() {
    return selectedPhotos.any((photo) => !sharedPhotos.contains(photo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Galería del Evento", style: AppTheme.appBarTextStyle), backgroundColor: AppTheme.primaryColor),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemCount: allPhotos.length,
        itemBuilder: (context, index) {
          File image = allPhotos[index]["file"] as File;
          String source = allPhotos[index]["source"] as String;
          String fileName = image.path.split('/').last;
          String userEmail = photoOwners[fileName] ?? "Only Yours";
          bool isSharedByUser = sharedPhotos.contains(fileName);
          bool isSelected = selectedPhotos.contains(image.path);

          return GestureDetector(
            onTap: () => _togglePhotoSelection(image.path, source),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(child: Image.file(image, fit: BoxFit.cover)),
                Positioned(bottom: 4, right: 4, child: _buildUserTag(userEmail, isSharedByUser)),
                if (isSelected)
                  const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 24),),
                if (isSharedByUser)
                  Positioned(top: 4, left: 4, 
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Shared", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
            ),
          );
        },
      ),
      floatingActionButton: _hasUnsharedSelectedPhotos()
              ? FloatingActionButton.extended(
                onPressed: _uploadSelectedPhotos,
                backgroundColor: AppTheme.primaryColor,
                label: Text("Subir (${selectedPhotos.length})", style: const TextStyle(color: Colors.white)),
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
              )
            : null,
    );
  }

  Widget _buildUserTag(String userEmail, bool isShared) {
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isShared ? Colors.green : Colors.blue, borderRadius: BorderRadius.circular(8)),
        child: Text(userEmail, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}
