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
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index].data() as Map<String, dynamic>;
              final teamA = match["teamA"] ?? "Desconocido";
              final teamB = match["teamB"] ?? "Desconocido";
              final date = (match["date"] as Timestamp?)?.toDate();

              final formattedDate = date != null
                  ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                  : "Sin fecha";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                    child: Icon(Icons.sports_soccer, color: Theme.of(context).primaryColor),
                  ),
                  title: Text("$teamA vs $teamB", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formattedDate, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 6),
                      if ((match['played'] ?? false) as bool)
                        Text('Resultado: ${(match['golesTeamA'] ?? 0).toString()} - ${(match['golesTeamB'] ?? 0).toString()}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                  onTap: () async {
                    // Abrir diálogo para editar resultado/marcar jugado
                    final docRef = snapshot.data!.docs[index].reference;
                    final gA = (match['golesTeamA'] ?? 0).toString();
                    final gB = (match['golesTeamB'] ?? 0).toString();
                    bool played = (match['played'] ?? false) as bool;
                    final TextEditingController aController = TextEditingController(text: gA);
                    final TextEditingController bController = TextEditingController(text: gB);

                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (ctx) {
                        return StatefulBuilder(
                          builder: (ctx2, setState) {
                            return AlertDialog(
                              title: const Text('Editar resultado'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SwitchListTile(
                                    value: played,
                                    onChanged: (v) => setState(() => played = v),
                                    title: const Text('Marcado como jugado'),
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                  if (played) ...[
                                    TextField(controller: aController, decoration: const InputDecoration(labelText: 'Goles Equipo A'), keyboardType: TextInputType.number),
                                    const SizedBox(height: 8),
                                    TextField(controller: bController, decoration: const InputDecoration(labelText: 'Goles Equipo B'), keyboardType: TextInputType.number),
                                  ]
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx2).pop(null), child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () {
                                    final Map<String, dynamic> out = {'played': played};
                                    if (played) {
                                      out['golesTeamA'] = int.tryParse(aController.text) ?? 0;
                                      out['golesTeamB'] = int.tryParse(bController.text) ?? 0;
                                    }
                                    Navigator.of(ctx2).pop(out);
                                  },
                                  child: const Text('Guardar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );

                    if (result != null) {
                      try {
                        await docRef.update(result);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resultado actualizado')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
                      }
                    }
                    aController.dispose();
                    bController.dispose();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
