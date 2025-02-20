import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ones_mvp/theme/theme.dart';

class InvitationsScreen extends StatefulWidget {
  final String userEmail;

  const InvitationsScreen({super.key, required this.userEmail});

  @override
  _InvitationsScreenState createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  /// **✅ Aceptar la invitación**
  Future<void> _acceptInvitation(String invitationId, String eventCode) async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // **2️⃣ Marcar la invitación como `accepted`**
      await _firestore.collection("invitations").doc(invitationId).update({
        "status": "accepted",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Invitación aceptada"), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("❌ Error al aceptar la invitación: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No se pudo aceptar la invitación."), backgroundColor: Colors.red),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  /// **❌ Rechazar la invitación**
  Future<void> _rejectInvitation(String invitationId) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection("invitations").doc(invitationId).update({
        "status": "rejected",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Invitación rechazada"), backgroundColor: Colors.orange),
      );
    } catch (e) {
      print("❌ Error al rechazar la invitación: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No se pudo rechazar la invitación."), backgroundColor: Colors.red),
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
        title: const Text("Invitaciones Pendientes", style: AppTheme.appBarTextStyle),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection("invitations")
              .where("email", isEqualTo: widget.userEmail)
              .where("status", isEqualTo: "invited")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("📭 No tienes invitaciones pendientes."));
            }

            var invitations = snapshot.data!.docs;

            return ListView.builder(
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                
                var invitation = invitations[index].data() as Map<String, dynamic>;
                String invitationId = invitations[index].id;
                String eventCode = invitation["eventCode"];
                print("📢 eventCode query $eventCode .");
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Colors.blue),
                    title: FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection("events").doc(eventCode).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text("Cargando evento...");
                        }
                        print("📢 snapshot.data $snapshot.data .");
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text("Evento no encontrado (Código: $eventCode)");
                        }
                        
                        String eventName = snapshot.data!.get("name") ?? "Evento sin nombre";
                        print("📢 eventName $eventName .");
                        return Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    //subtitle: Text("Código: $eventCode"),
                    trailing: isLoading
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _acceptInvitation(invitationId, eventCode),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _rejectInvitation(invitationId),
                              ),
                            ],
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
