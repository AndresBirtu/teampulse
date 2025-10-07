import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
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
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No se encontraron datos del usuario"));
          }

          final userData = snapshot.data!;
          final role = userData["role"] ?? "jugador";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Text("👋 Hola, ${userData["name"] ?? "Usuario"}",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

              
                Card(
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 40, color: Colors.blue),
                    title: Text(userData["name"] ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Correo: ${userData["email"] ?? ""}"),
                        Text("Rol: $role"),
                        if (userData["teamName"] != null)
                          Text("Equipo: ${userData["teamName"]}"),
                        if (userData["teamCode"] != null)
                          Text("Código: ${userData["teamCode"]}"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                
                Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📊 Estadísticas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _StatBox(label: "Partidos", value: "12"),
                            _StatBox(label: "Goles", value: "8"),
                            _StatBox(label: "Asistencias", value: "5"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),


                Card(
                  color: Colors.green[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("⚡ Acciones rápidas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: role == "entrenador"
                              ? [
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.group_add),
                                    label: const Text("Invitar jugador"),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Editar equipo"),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.bar_chart),
                                    label: const Text("Estadísticas del equipo"),
                                  ),
                                ]
                              : [
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.bar_chart),
                                    label: const Text("Mis estadísticas"),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.event),
                                    label: const Text("Próximos partidos"),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Editar perfil"),
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                
                if (role == "entrenador" && userData["teamCode"] != null)
                  _TeamPlayers(teamCode: userData["teamCode"]),
              ],
            ),
          );
        },
      ),
    );
  }
}


class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}


class _TeamPlayers extends StatelessWidget {
  final String teamCode;
  const _TeamPlayers({required this.teamCode});

  @override
  Widget build(BuildContext context) {
    final playersRef = FirebaseFirestore.instance
        .collection("teams")
        .doc(teamCode)
        .collection("players");

    return Card(
      color: Colors.purple[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("👥 Jugadores del equipo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: playersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("Cargando jugadores...");
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text("No hay jugadores en el equipo");
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(data["name"] ?? ""),
                      subtitle: Text(data["role"] ?? ""),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
