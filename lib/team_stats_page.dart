import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamStatsPage extends StatelessWidget {
  final String teamId;

  const TeamStatsPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas del equipo"),
        backgroundColor: Colors.blue[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .collection('players')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;

          if (players.isEmpty) {
            return const Center(
              child: Text("No hay jugadores en el equipo"),
            );
          }

         
          int totalGoles = 0;
          int totalAsistencias = 0;
          int totalPartidos = 0;
          int totalMinutos = 0;
          int totalAmarillas = 0;
          int totalRojas = 0;

          for (var player in players) {
            final data = player.data() as Map<String, dynamic>;
            totalGoles += (data['goles'] as int?) ?? 0;
            totalAsistencias += (data['asistencias'] as int?) ?? 0;
            totalPartidos += (data['partidos'] as int?) ?? 0;
            totalMinutos += (data['minutos'] as int?) ?? 0;
            totalAmarillas += (data['tarjetas_amarillas'] as int?) ?? 0;
            totalRojas += (data['tarjetas_rojas'] as int?) ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                const Text(
                  "Resumen del equipo",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(
                      icon: Icons.sports_soccer,
                      label: "Goles",
                      value: totalGoles.toString(),
                      color: Colors.green,
                    ),
                    _StatBox(
                      icon: Icons.group,
                      label: "Asistencias",
                      value: totalAsistencias.toString(),
                      color: Colors.orange,
                    ),
                    _StatBox(
                      icon: Icons.sports,
                      label: "Partidos",
                      value: totalPartidos.toString(),
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(
                      icon: Icons.timer,
                      label: "Minutos",
                      value: totalMinutos.toString(),
                      color: Colors.purple,
                    ),
                    _StatBox(
                      icon: Icons.warning,
                      label: "Amarillas",
                      value: totalAmarillas.toString(),
                      color: Colors.amber,
                    ),
                    _StatBox(
                      icon: Icons.close,
                      label: "Rojas",
                      value: totalRojas.toString(),
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

               
                const Text(
                  "Estadísticas por jugador",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...players.map((playerDoc) {
                  final playerData = playerDoc.data() as Map<String, dynamic>;
                  return _PlayerStatCard(
                    name: playerData['name'] ?? "Jugador desconocido",
                    goles: (playerData['goles'] as int?) ?? 0,
                    asistencias: (playerData['asistencias'] as int?) ?? 0,
                    partidos: (playerData['partidos'] as int?) ?? 0,
                    minutos: (playerData['minutos'] as int?) ?? 0,
                    amarillas: (playerData['tarjetas_amarillas'] as int?) ?? 0,
                    rojas: (playerData['tarjetas_rojas'] as int?) ?? 0,
                    posicion: playerData['posicion'] ?? "No especificada",
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatCard extends StatelessWidget {
  final String name;
  final int goles;
  final int asistencias;
  final int partidos;
  final int minutos;
  final int amarillas;
  final int rojas;
  final String posicion;

  const _PlayerStatCard({
    required this.name,
    required this.goles,
    required this.asistencias,
    required this.partidos,
    required this.minutos,
    required this.amarillas,
    required this.rojas,
    required this.posicion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Posición: $posicion",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: "Partidos", value: partidos.toString()),
                _StatItem(label: "Goles", value: goles.toString()),
                _StatItem(label: "Asistencias", value: asistencias.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: "Minutos", value: minutos.toString()),
                _StatItem(label: "Am.", value: amarillas.toString(), color: Colors.amber),
                _StatItem(label: "Rojas", value: rojas.toString(), color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
