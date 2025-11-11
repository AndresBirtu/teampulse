import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teampulse/home_page.dart';
import 'match_page.dart';
import 'players_page.dart';
import 'full_stats_page.dart';
import 'team_stats_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showInviteDialog(BuildContext context, String teamId) {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Invitar jugador"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: "Email del jugador",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingresa un email válido")),
                );
                return;
              }

              try {
            
                final usersSnapshot = await FirebaseFirestore.instance
                    .collection("users")
                    .where("email", isEqualTo: email)
                    .get();

                if (usersSnapshot.docs.isEmpty) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Usuario no encontrado")),
                    );
                  }
                  return;
                }

                final userId = usersSnapshot.docs.first.id;

           
                await FirebaseFirestore.instance
                    .collection("teams")
                    .doc(teamId)
                    .collection("players")
                    .doc(userId)
                    .set({
                  "name": usersSnapshot.docs.first["name"] ?? "Jugador",
                  "email": email,
                  "goles": 0,
                  "asistencias": 0,
                  "posicion": "",
                  "partidos": 0,
                  "minutos": 0,
                  "tarjetas_amarillas": 0,
                  "tarjetas_rojas": 0,
                }, SetOptions(merge: true));

        
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .set({"teamId": teamId}, SetOptions(merge: true));

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jugador invitado correctamente ✅")),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            child: const Text("Invitar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Usuario no encontrado"));
    }

    final userStream = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Cerrar sesión"),
                  content: const Text(
                    "¿Estás seguro de que quieres cerrar sesión?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(ctx).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text("Salir"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final role = userData["role"] ?? "jugador";
          final teamId = userData["teamId"] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.blue[800],
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Hola, ${userData["name"] ?? "Usuario"} 👋",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("teams")
                      .doc(teamId)
                      .collection("players")
                      .doc(uid)
                      .snapshots(),
                  builder: (context, statsSnapshot) {
                    if (!statsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final statsData =
                        statsSnapshot.data!.data() as Map<String, dynamic>? ??
                        {};

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: (role == "entrenador")
                              ? [
                                  _StatCard(
                                    icon: Icons.sports_soccer,
                                    label: "Jugados",
                                    value: "15",
                                    color: Colors.orange,
                                  ),
                                  _StatCard(
                                    icon: Icons.emoji_events,
                                    label: "Ganados",
                                    value: "10",
                                    color: Colors.green,
                                  ),
                                  _StatCard(
                                    icon: Icons.cancel,
                                    label: "Perdidos",
                                    value: "5",
                                    color: Colors.red,
                                  ),
                                ]
                              : [
                                  _StatCard(
                                    icon: Icons.sports_soccer,
                                    label: "Partidos",
                                    value: (statsData["partidos"] ?? 0)
                                        .toString(),
                                    color: Colors.blue,
                                  ),
                                  _StatCard(
                                    icon: Icons.sports,
                                    label: "Goles",
                                    value: (statsData["goles"] ?? 0).toString(),
                                    color: Colors.green,
                                  ),
                                  _StatCard(
                                    icon: Icons.group,
                                    label: "Asistencias",
                                    value: (statsData["asistencias"] ?? 0)
                                        .toString(),
                                    color: Colors.orange,
                                  ),
                                ],
                        ),
                        if (role == "jugador")
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.bar_chart,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Ver estadísticas completas",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullStatsPage(
                                      teamId: teamId,
                                      playerId: uid,
                                      playerName: userData["name"] ?? "Jugador",
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),

                role == "entrenador"
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Gestión del equipo",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[800],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.group, color: Colors.white),
                                    label: const Text(
                                      "Ver jugadores",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PlayersPage(teamId: teamId),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.sports_soccer, color: Colors.white),
                                    label: const Text(
                                      "Partidos",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MatchesPage(teamId: teamId),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.person_add, color: Colors.white),
                                    label: const Text(
                                      "Invitar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      _showInviteDialog(context, teamId);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.bar_chart, color: Colors.white),
                                    label: const Text(
                                      "Estadísticas",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TeamStatsPage(teamId: teamId),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Próximos partidos",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("teams")
                                .doc(teamId)
                                .collection("matches")
                                .orderBy("date", descending: false)
                                .snapshots(),
                            builder: (context, matchSnapshot) {
                              if (!matchSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final matches = matchSnapshot.data!.docs;

                              if (matches.isEmpty) {
                                return const Text(
                                  "No hay partidos programados todavía ⚽",
                                );
                              }

                              return Column(
                                children: matches.map((matchDoc) {
                                  final matchData =
                                      matchDoc.data() as Map<String, dynamic>;
                                  final teamA =
                                      matchData["teamA"] ?? "Desconocido";
                                  final teamB =
                                      matchData["teamB"] ?? "Desconocido";
                                  final date = (matchData["date"] as Timestamp)
                                      .toDate();

                                  final formattedDate =
                                      "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: Icon(Icons.sports_soccer, color: Colors.blue[800]),
                                      title: Text("$teamA vs $teamB", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(formattedDate),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}
