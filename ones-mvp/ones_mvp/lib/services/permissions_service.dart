import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions() async {
  print("📢 Verificando permisos...");

  // Solicitar permisos
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
    Permission.manageExternalStorage, // Para Android 10+
  ].request();

  bool cameraGranted = statuses[Permission.camera] == PermissionStatus.granted;
  bool storageGranted = statuses[Permission.storage] == PermissionStatus.granted;
  bool manageStorageGranted = statuses[Permission.manageExternalStorage] == PermissionStatus.granted;

  print("📢 Permisos -> Cámara: $cameraGranted, Almacenamiento: $storageGranted, Gestión: $manageStorageGranted");

  if (cameraGranted && (storageGranted || manageStorageGranted)) {
    print("✅ Todos los permisos concedidos.");
    return true;
  } else {
    print("❌ Permiso denegado.");
    
    if (statuses[Permission.camera] == PermissionStatus.permanentlyDenied ||
        statuses[Permission.storage] == PermissionStatus.permanentlyDenied) {
      print("⚠️ Permiso denegado permanentemente. Abriendo configuración...");
      openAppSettings();
    }
    return false;
  }
}
