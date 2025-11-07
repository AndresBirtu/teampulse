import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_player_page.dart';

class PlayersPage extends StatelessWidget {
  final String teamId;

  const PlayersPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final playersStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jugadores del equipo"),
        backgroundColor: Colors.blue[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: playersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;

          if (players.isEmpty) {
            return const Center(child: Text("No hay jugadores en el equipo"));
          }

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final playerData = player.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    playerData['name'] ?? 'Jugador sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Posición: ${playerData['posicion'] ?? '-'}\n"
                    "Partidos: ${playerData['partidos'] ?? 0} | "
                    "Goles: ${playerData['goles'] ?? 0} | "
                    "Asistencias: ${playerData['asistencias'] ?? 0}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPlayerPage(
                            teamId: teamId,
                            playerId: player.id,
                            playerData: playerData,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
