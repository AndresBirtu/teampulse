import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FullStatsPage extends StatelessWidget {
  final String teamId;
  final String playerId;
  final String playerName;

  const FullStatsPage({
    super.key,
    required this.teamId,
    required this.playerId,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final playerStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas completas: $playerName'),
        backgroundColor: Colors.blue[800],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: playerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final playerData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 36, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(playerName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _StatCard(label: 'Partidos jugados', value: playerData['partidos']?.toString() ?? '0'),
                _StatCard(label: 'Goles', value: playerData['goles']?.toString() ?? '0'),
                _StatCard(label: 'Asistencias', value: playerData['asistencias']?.toString() ?? '0'),
                _StatCard(label: 'Minutos jugados', value: playerData['minutos']?.toString() ?? '0'),
                _StatCard(label: 'Tarjetas amarillas', value: playerData['tarjetas_amarillas']?.toString() ?? '0'),
                _StatCard(label: 'Tarjetas rojas', value: playerData['tarjetas_rojas']?.toString() ?? '0'),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 15)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
