import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!;
          final role = userData["role"] ?? "jugador";

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
                            value: "12",
                            color: Colors.blue,
                          ),
                          _StatCard(
                            icon: Icons.sports,
                            label: "Goles",
                            value: "8",
                            color: Colors.green,
                          ),
                          _StatCard(
                            icon: Icons.group,
                            label: "Asistencias",
                            value: "5",
                            color: Colors.orange,
                          ),
                        ],
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
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.group),
                                  title: const Text("Ver jugadores"),
                                  onTap: () {},
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
                                  title: const Text(
                                    "Ver estadísticas del equipo",
                                  ),
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
                                        builder: (context) => MatchesPage(
                                          teamId: userData["teamId"],
                                        ),
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MatchCard(
                            "Equipo A vs Equipo B",
                            "Sábado 12:00 - Campo 1",
                          ),
                          _MatchCard(
                            "Equipo C vs Equipo D",
                            "Domingo 18:00 - Campo 2",
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
