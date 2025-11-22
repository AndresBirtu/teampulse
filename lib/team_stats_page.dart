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
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
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

          // Calcular estadísticas generales
          int totalGoles = 0;
          int totalAsistencias = 0;
          int totalPartidos = 0;
          int totalMinutos = 0;
          int totalAmarillas = 0;
          int totalRojas = 0;

          int numJugadores = 0;

          for (var player in players) {
            final data = player.data() as Map<String, dynamic>;
            // Excluir entrenadores del cálculo
            final role = (data['role'] as String?) ?? '';
            if (role.toLowerCase() == 'entrenador' || role.toLowerCase() == 'coach') continue;

            totalGoles += (data['goles'] as int?) ?? 0;
            totalAsistencias += (data['asistencias'] as int?) ?? 0;
            totalPartidos += (data['partidos'] as int?) ?? 0;
            totalMinutos += (data['minutos'] as int?) ?? 0;
            totalAmarillas += (data['tarjetas_amarillas'] as int?) ?? 0;
            totalRojas += (data['tarjetas_rojas'] as int?) ?? 0;
            numJugadores++;
          }

          // Calcular promedios (evitar división por cero)
          double promGoles = numJugadores > 0 ? totalGoles / numJugadores : 0.0;
          double promAsistencias = numJugadores > 0 ? totalAsistencias / numJugadores : 0.0;
          double promMinutos = numJugadores > 0 ? totalMinutos / numJugadores : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen general - Totales
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📊 TOTALES DEL EQUIPO",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBoxTotal(
                            icon: Icons.sports_soccer,
                            label: "Goles",
                            value: totalGoles.toString(),
                            color: Colors.greenAccent,
                          ),
                          _StatBoxTotal(
                            icon: Icons.group,
                            label: "Asistencias",
                            value: totalAsistencias.toString(),
                            color: Colors.orangeAccent,
                          ),
                          _StatBoxTotal(
                            icon: Icons.sports,
                            label: "Partidos",
                            value: totalPartidos.toString(),
                            color: Colors.lightBlueAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBoxTotal(
                            icon: Icons.timer,
                            label: "Minutos",
                            value: totalMinutos.toString(),
                            color: Colors.purpleAccent,
                          ),
                          _StatBoxTotal(
                            icon: Icons.warning,
                            label: "Amarillas",
                            value: totalAmarillas.toString(),
                            color: Colors.amber,
                          ),
                          _StatBoxTotal(
                            icon: Icons.close,
                            label: "Rojas",
                            value: totalRojas.toString(),
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Promedios
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📈 PROMEDIOS ($numJugadores jugadores)",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBoxPromedio(
                            label: "Goles/Jug",
                            value: promGoles.toStringAsFixed(1),
                            color: Colors.greenAccent,
                          ),
                          _StatBoxPromedio(
                            label: "Asist/Jug",
                            value: promAsistencias.toStringAsFixed(1),
                            color: Colors.orangeAccent,
                          ),
                          _StatBoxPromedio(
                            label: "Min/Jug",
                            value: promMinutos.toStringAsFixed(0),
                            color: Colors.lightBlueAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Estadísticas por jugador
                const Text(
                  "👥 ESTADÍSTICAS POR JUGADOR",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...players.where((playerDoc) {
                  final playerData = playerDoc.data() as Map<String, dynamic>;
                  final role = (playerData['role'] as String?) ?? '';
                  // Excluir entrenadores de la lista
                  return role.toLowerCase() != 'entrenador' && role.toLowerCase() != 'coach';
                }).map((playerDoc) {
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

class _StatBoxTotal extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBoxTotal({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBoxPromedio extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBoxPromedio({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              textAlign: TextAlign.center,
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
    // Determinar color según posición
    Color posicionColor = Colors.blue;
    IconData posicionIcon = Icons.sports_soccer;

    if (posicion.toLowerCase().contains("portero") ||
        posicion.toLowerCase().contains("keeper")) {
      posicionColor = Colors.purple;
      posicionIcon = Icons.security;
    } else if (posicion.toLowerCase().contains("defensa")) {
      posicionColor = Colors.red;
      posicionIcon = Icons.shield;
    } else if (posicion.toLowerCase().contains("centrocampista") ||
        posicion.toLowerCase().contains("medio")) {
      posicionColor = Colors.orange;
      posicionIcon = Icons.trending_up;
    } else if (posicion.toLowerCase().contains("delantero") ||
        posicion.toLowerCase().contains("ataque")) {
      posicionColor = Colors.green;
      posicionIcon = Icons.flash_on;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: posicionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      posicionIcon,
                      color: posicionColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: posicionColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            posicion,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: posicionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      label: "Partidos",
                      value: partidos.toString(),
                      icon: Icons.sports_soccer,
                      color: Colors.blue,
                    ),
                    _StatItem(
                      label: "Goles",
                      value: goles.toString(),
                      icon: Icons.sports,
                      color: Colors.green,
                    ),
                    _StatItem(
                      label: "Asistencias",
                      value: asistencias.toString(),
                      icon: Icons.group,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    label: "Minutos",
                    value: minutos.toString(),
                    icon: Icons.timer,
                    color: Colors.purple,
                  ),
                  _StatItem(
                    label: "Amarillas",
                    value: amarillas.toString(),
                    icon: Icons.warning,
                    color: Colors.amber,
                  ),
                  _StatItem(
                    label: "Rojas",
                    value: rojas.toString(),
                    icon: Icons.close,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
