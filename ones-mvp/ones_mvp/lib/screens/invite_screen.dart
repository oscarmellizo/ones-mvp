import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ones_mvp/theme/theme.dart';
import 'package:uuid/uuid.dart';

class InviteScreen extends StatefulWidget {
  final String eventCode;

  const InviteScreen({super.key, required this.eventCode});

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  bool isLoading = false;

  /// **📤 Enviar invitación a Firestore**
  Future<void> _sendInvitation() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📌 Ingresa un correo válido."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String invitationId = _uuid.v4();
      await _firestore.collection("invitations").doc(invitationId).set({
        "eventCode": widget.eventCode.split('/').last,
        "email": email,
        "status": "invited", // Estado inicial
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() {
        _emailController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Invitación enviada a $email"), backgroundColor: AppTheme.primaryColor),
      );
    } catch (e) {
      print("❌ Error al enviar invitación: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No se pudo enviar la invitación."), backgroundColor: Colors.red),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invitar Participantes", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Ingresa el correo electrónico de la persona que quieres invitar al evento.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _sendInvitation,
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar Invitación"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
            const SizedBox(height: 30),
            _buildInvitationsList(), // ✅ Lista de invitaciones enviadas
          ],
        ),
      ),
    );
  }

  /// **📜 Muestra la lista de invitaciones enviadas**
  Widget _buildInvitationsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("invitations")
            .where("eventCode", isEqualTo: widget.eventCode.split('/').last)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay invitaciones enviadas aún."));
          }

          var invitations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              var invitation = invitations[index].data() as Map<String, dynamic>;
              String email = invitation["email"];
              String status = invitation["status"];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: _buildStatusTag(status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// **🟢 Muestra el estado de la invitación con un badge de color**
  Widget _buildStatusTag(String status) {
    Color badgeColor;
    String statusText;

    switch (status) {
      case "accepted":
        badgeColor = Colors.green;
        statusText = "Aceptada";
        break;
      case "rejected":
        badgeColor = Colors.red;
        statusText = "Rechazada";
        break;
      default:
        badgeColor = Colors.orange;
        statusText = "Pendiente";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
