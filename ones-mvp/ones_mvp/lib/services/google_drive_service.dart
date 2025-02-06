import 'dart:io';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  final String folderId =
      "1ofl14GJ0CveDDoeit_xa80Xmmtchz6ou"; // ⚠️ Reemplázalo con el ID de la carpeta en Google Drive

  Future<AutoRefreshingAuthClient> getAuthClient() async {
    try {
      // 📢 Carga el archivo de credenciales desde los assets
      String credentials =
          await rootBundle.loadString('assets/service_account.json');
      final accountCredentials =
          ServiceAccountCredentials.fromJson(json.decode(credentials));

      print("🔑 Autenticando con Google Drive...");

      // 🔓 Autenticación con la cuenta de servicio
      final client = await clientViaServiceAccount(
        accountCredentials,
        [drive.DriveApi.driveFileScope],
      );

      print("✅ Autenticación exitosa.");
      return client;
    } catch (e) {
      print("❌ Error en la autenticación: $e");
      rethrow;
    }
  }

  Future<String?> uploadFileToDrive(File file) async {
    try {
      final authClient = await getAuthClient();
      final driveApi = drive.DriveApi(authClient);

      final driveFile = drive.File()
        ..name = basename(file.path)
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());

      final uploadedFile =
          await driveApi.files.create(driveFile, uploadMedia: media);

      print("✅ Archivo subido con éxito. ID: ${uploadedFile.id}");
      return uploadedFile.id;
    } catch (e) {
      print("❌ Error al subir archivo a Google Drive: $e");
      return null;
    }
  }

  Future<ServiceAccountCredentials> loadServiceAccountCredentials() async {
    try {
      print("🔑 Cargando credenciales desde assets/service_account.json...");

      final jsonString =
          await rootBundle.loadString('assets/service_account.json');
      final jsonData = json.decode(jsonString);

      return ServiceAccountCredentials.fromJson(jsonData);
    } catch (e) {
      print("❌ Error al cargar las credenciales: $e");
      throw Exception(
          "No se pudo cargar el archivo service_account.json. Verifica que esté en assets/");
    }
  }

  // Autenticación con Google Drive
  Future<drive.DriveApi> _getDriveApi() async {
    final credentials = await loadServiceAccountCredentials();
    final authClient = await clientViaServiceAccount(
        credentials, [drive.DriveApi.driveFileScope]);
    return drive.DriveApi(authClient);
  }

  // 📥 Descargar imágenes desde Google Drive y guardarlas temporalmente
  Future<List<File>> fetchImagesFromDrive() async {
    try {
      print("📂 Recuperando imágenes de Google Drive...");

      final driveApi = await _getDriveApi();
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType contains 'image/'",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      List<File> localFiles = [];

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var file in fileList.files!) {
          if (file.id != null) {
            print("📂 Archivo recuperado: ${file.name}");

            try {
              // 🔽 Descargar imagen desde Drive
              final tempDir = await getTemporaryDirectory();
              final File tempFile = File('${tempDir.path}/${file.name}');

              var mediaStream = await driveApi.files.get(
                file.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              );

              if (mediaStream is drive.Media) {
                List<int> dataBytes = [];
                mediaStream.stream.listen(
                  (List<int> chunk) {
                    dataBytes.addAll(chunk);
                  },
                  onDone: () async {
                    await tempFile.writeAsBytes(dataBytes);
                    localFiles.add(tempFile);
                    print("✅ Imagen descargada: ${tempFile.path}");
                  },
                  onError: (e) {
                    print("❌ Error en la transmisión de datos: $e");
                  },
                );
              } else {
                print(
                    "⚠️ Respuesta inesperada al intentar descargar ${file.name}");
              }
            } catch (e) {
              print("❌ No se pudo descargar la imagen ${file.name}: $e");
            }
          }
        }
        print("✅ ${localFiles.length} imágenes descargadas desde Drive.");
      } else {
        print("⚠️ No se encontraron imágenes en Drive.");
      }

      return localFiles;
    } catch (e) {
      print("❌ Error obteniendo imágenes de Drive: $e");
      return [];
    }
  }
}
