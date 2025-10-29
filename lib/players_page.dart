import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_player_page.dart';

class PlayersPage extends StatelessWidget {
  final String teamId;

  const PlayersPage({super.key, required this.teamId});

  Future<String?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return userDoc.data()?['role'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jugadores del equipo"),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<String?>(
        future: _getUserRole(),
        builder: (context, roleSnapshot) {
          if (!roleSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isEntrenador = roleSnapshot.data == 'entrenador';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("teams")
                .doc(teamId)
                .collection("players")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay jugadores en el equipo"));
              }

              final players = snapshot.data!.docs
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['role'] == 'jugador';
                  })
                  .toList();

              if (players.isEmpty) {
                return const Center(child: Text("No hay jugadores en el equipo"));
              }

              return ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final playerDoc = players[index];
                  final data = playerDoc.data() as Map<String, dynamic>;
                  final playerName = data['name'] ?? "Sin nombre";
                  final dorsal = data['dorsal']?.toString() ?? "-";

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[800],
                        child: Text(
                          dorsal,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        playerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Goles: ${data['goles'] ?? 0} | Asistencias: ${data['asistencias'] ?? 0}",
                      ),
                      trailing: isEntrenador
                          ? IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPlayerPage(
                                      teamId: teamId,
                                      playerId: playerDoc.id,
                                      playerData: data,
                                    ),
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
