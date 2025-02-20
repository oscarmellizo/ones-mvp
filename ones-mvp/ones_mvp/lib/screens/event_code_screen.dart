import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ones_mvp/screens/menu_screen.dart';
import 'package:ones_mvp/screens/invitations_screen.dart'; // Nueva pantalla de invitaciones
import 'package:ones_mvp/theme/theme.dart';
import 'package:uuid/uuid.dart';

class EventCodeScreen extends StatefulWidget {
  final User user;
  const EventCodeScreen({super.key, required this.user});

  @override
  _EventCodeScreenState createState() => _EventCodeScreenState();
}

class _EventCodeScreenState extends State<EventCodeScreen> {
  List<Map<String, String>> eventList = [];
  int invitationCount = 0; // 🔹 Contador de invitaciones pendientes
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndRegisterUser();
    _fetchUserEvents();
    _fetchPendingInvitations();
  }

  /// **🔍 Verifica si el usuario ya está en Firestore, si no, lo registra**
  Future<void> _checkAndRegisterUser() async {
    try {
      final userDoc = await _firestore.collection('users').where('email', isEqualTo: widget.user.email).limit(1).get();

      if (userDoc.docs.isEmpty) {
        String userId = _uuid.v4();
        await _firestore.collection('users').doc(userId).set({
          "email": widget.user.email,
          "name": widget.user.displayName?.split(" ").first ?? widget.user.email!.split('@')[0],
        });

        print("✅ Usuario ${widget.user.email} registrado en Firestore.");
      } else {
        print("📂 Usuario ${widget.user.email} ya registrado en Firestore.");
      }
    } catch (e) {
      print("❌ Error al verificar/registrar usuario: $e");
    }
  }

  /// **📩 Consultar cantidad de invitaciones pendientes**
  Future<void> _fetchPendingInvitations() async {
    try {
      final querySnapshot = await _firestore
          .collection('invitations')
          .where('email', isEqualTo: widget.user.email?.toLowerCase())
          .where('status', isEqualTo: 'invited')
          .get();

      setState(() {
        invitationCount = querySnapshot.docs.length;
      });

      print("📢 Tienes $invitationCount invitaciones pendientes.");
    } catch (e) {
      print("❌ Error al obtener invitaciones: $e");
    }
  }

  /// **🔄 Consultar eventos del usuario en Firestore**
  Future<void> _fetchUserEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('owner', isEqualTo: widget.user.email)
          .get();

      List<Map<String, String>> fetchedEvents = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "name": data["name"]?.toString() ?? "Evento sin nombre",
          "path": data["path"]?.toString() ?? "",
          "image": data["image"]?.toString() ?? "assets/birthday.png",
          "folderId": data["folderId"]?.toString() ?? "",
        };
      }).toList();

      setState(() {
        eventList = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error al obtener eventos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  
  /// **🚀 Crear un nuevo evento**
  Future<void> _createEvent() async {
    TextEditingController eventNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Crear Nuevo Evento"),
        content: TextField(
          controller: eventNameController,
          decoration: const InputDecoration(labelText: "Nombre del Evento"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              String eventName = eventNameController.text.trim();
              if (eventName.isEmpty) return;

              Navigator.pop(context);
              await _saveEventToFirestore(eventName);
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  /// **💾 Guardar evento en Firestore**
  Future<void> _saveEventToFirestore(String eventName) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("❌ No hay usuario autenticado.");
    return;
  }

  try {
    String eventId = _uuid.v4().substring(0, 8).toUpperCase();
    String eventPath = "/storage/emulated/0/Ones/$eventId";

    // Obtener un folderId disponible
    final folderSnapshot = await _firestore.collection('folderIds').where('used', isEqualTo: false).limit(1).get();
    if (folderSnapshot.docs.isEmpty) {
      print("❌ No hay folderIds disponibles.");
      return;
    }
    String folderId = folderSnapshot.docs.first.id;

    // Marcar folderId como usado
    await _firestore.collection('folderIds').doc(folderId).update({'used': true});

    // Crear el evento en Firestore
    await _firestore.collection('events').doc(eventId).set({
      "name": eventName,
      "path": eventPath,
      "image": "assets/birthday.png",
      "folderId": folderId,
      "owner": user.email,  // 📌 Asegurarse de enviar el email autenticado correctamente
    });

    print("✅ Evento '$eventName' creado correctamente.");
    _fetchUserEvents(); // Refrescar la lista de eventos en pantalla
  } catch (e) {
    print("❌ Error al crear evento: $e");
  }
}


  /// **🔗 Navegar al evento seleccionado**
  void navigateToEvent(String eventPath, String folderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MenuScreen(eventCode: eventPath, folderId: folderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Eventos", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createEvent,
          ),
          // 🔔 Botón de notificaciones
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvitationsScreen(userEmail: widget.user.email ?? ""),
                    ),
                  ).then((_) => _fetchPendingInvitations()); // Actualizar después de ver invitaciones
                },
              ),
              if (invitationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$invitationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserProfile(),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: eventList.isEmpty
                        ? const Center(child: Text("No tienes eventos aún. ¡Crea uno!"))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: eventList.length,
                            itemBuilder: (context, index) {
                              final event = eventList[index];
                              return GestureDetector(
                                onTap: () => _navigateToEvent(event["path"]!, event["folderId"]!),
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
          ],
        ),
      ),
    );
  }

  /// **🔗 Navegar al evento seleccionado**
  void _navigateToEvent(String eventPath, String folderId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MenuScreen(eventCode: eventPath, folderId: folderId)),
    );
  }

  /// **👤 Widget para mostrar la información del usuario autenticado**
  Widget _buildUserProfile() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null,
          radius: 25,
          child: widget.user.photoURL == null ? const Icon(Icons.person, size: 30) : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hola, ${widget.user.displayName ?? 'Usuario'}!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.user.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
