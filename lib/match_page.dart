import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_match_page.dart';

class MatchesPage extends StatelessWidget {
  final String teamId;
  const MatchesPage({required this.teamId, super.key});

  @override
  Widget build(BuildContext context) {
    print("📡 Cargando partidos para teamId: $teamId"); 

    if (teamId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("❌ Error: No se encontró el equipo")),
      );
    }

    final matchesStream = FirebaseFirestore.instance
        .collection("teams")
        .doc(teamId)
        .collection("matches")
        .orderBy("date", descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de partidos"),
        backgroundColor: Colors.blue[800],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMatchPage(teamId: teamId)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: matchesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay partidos registrados"));
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index].data() as Map<String, dynamic>;
              final teamA = match["teamA"] ?? "Desconocido";
              final teamB = match["teamB"] ?? "Desconocido";
              final date = (match["date"] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.sports_soccer, color: Colors.blue),
                  title: Text("$teamA vs $teamB"),
                  subtitle: Text(date != null
                      ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                      : "Sin fecha"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
