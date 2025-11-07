  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:teampulse/home_page.dart';
  import 'match_page.dart';
  import 'players_page.dart';

  class DashboardPage extends StatelessWidget {
    const DashboardPage({super.key});

    @override
    Widget build(BuildContext context) {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        return const Center(child: Text("Usuario no encontrado"));
      }

      
      final userStream =
          FirebaseFirestore.instance.collection("users").doc(uid).snapshots();

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
                    content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(ctx).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const HomePage()),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Colors.blue[800],
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 32, color: Colors.blue),
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
                          statsSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: (role == "entrenador")
                            ? [
                                _StatCard(
                                    icon: Icons.sports_soccer,
                                    label: "Jugados",
                                    value: "15",
                                    color: Colors.orange),
                                _StatCard(
                                    icon: Icons.emoji_events,
                                    label: "Ganados",
                                    value: "10",
                                    color: Colors.green),
                                _StatCard(
                                    icon: Icons.cancel,
                                    label: "Perdidos",
                                    value: "5",
                                    color: Colors.red),
                              ]
                            : [
                                _StatCard(
                                    icon: Icons.sports_soccer,
                                    label: "Partidos",
                                    value: (statsData["partidos"] ?? 0).toString(),
                                    color: Colors.blue),
                                _StatCard(
                                    icon: Icons.sports,
                                    label: "Goles",
                                    value: (statsData["goles"] ?? 0).toString(),
                                    color: Colors.green),
                                _StatCard(
                                    icon: Icons.group,
                                    label: "Asistencias",
                                    value: (statsData["asistencias"] ?? 0).toString(),
                                    color: Colors.orange),
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
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.group),
                                    title: const Text("Ver jugadores"),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PlayersPage(teamId: teamId),
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.person_add),
                                    title: const Text("Invitar jugadores"),
                                    onTap: () {},
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.bar_chart),
                                    title: const Text("Ver estadísticas del equipo"),
                                    onTap: () {},
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.sports_soccer),
                                    title: const Text("Gestión de partidos"),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MatchesPage(teamId: teamId),
                                        ),
                                      );
                                    },
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
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _MatchCard("Equipo A vs Equipo B", "Sábado 12:00 - Campo 1"),
                            _MatchCard("Equipo C vs Equipo D", "Domingo 18:00 - Campo 2"),
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

    const _StatCard(
        {required this.icon,
        required this.label,
        required this.value,
        required this.color});

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
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label),
            ],
          ),
        ),
      );
    }
  }

  class _MatchCard extends StatelessWidget {
    final String title;
    final String subtitle;

    const _MatchCard(this.title, this.subtitle);

    @override
    Widget build(BuildContext context) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(Icons.sports_soccer, color: Colors.blue[800]),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
        ),
      );
    }
  }
