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
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final playerData = player.data() as Map<String, dynamic>;
              final name = playerData['name'] ?? 'Jugador sin nombre';
              final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                    child: Text(initials.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    "Posición: ${playerData['posicion'] ?? '-'} · Partidos: ${playerData['partidos'] ?? 0}\nGoles: ${playerData['goles'] ?? 0} · Asist: ${playerData['asistencias'] ?? 0}",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
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
