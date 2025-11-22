import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_match_page.dart';
import 'match_stats_editor.dart';
import 'match_availability_page.dart';

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
        child: Icon(Icons.add, color: Colors.white),
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
                        // Actualizar el documento del partido
                        await docRef.update(result);

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resultado actualizado')));

                        // Si marcó como jugado, aplicar agregación de stats a players (una sola vez)
                        final previouslyAggregated = (match['aggregated'] ?? false) as bool;
                        final nowPlayed = (result['played'] ?? false) as bool;
                        if (nowPlayed && !previouslyAggregated) {
                          try {
                            final statsSnap = await docRef.collection('stats').get();
                            final batch = FirebaseFirestore.instance.batch();
                            for (final s in statsSnap.docs) {
                              final sd = s.data() as Map<String, dynamic>;
                              final pid = s.id;
                              final goles = (sd['goles'] ?? 0) as int;
                              final asist = (sd['asistencias'] ?? 0) as int;
                              final minutos = (sd['minutos'] ?? 0) as int;
                              final amar = (sd['amarillas'] ?? 0) as int;
                              final roj = (sd['rojas'] ?? 0) as int;
                              final convocado = (sd['convocado'] ?? true) as bool;
                              if (!convocado) continue;

                              final playerRef = FirebaseFirestore.instance.collection('teams').doc(teamId).collection('players').doc(pid);
                              batch.set(playerRef, {
                                'goles': FieldValue.increment(goles),
                                'asistencias': FieldValue.increment(asist),
                                'minutos': FieldValue.increment(minutos),
                                'partidos': FieldValue.increment((minutos > 0) ? 1 : 0),
                                'tarjetas_amarillas': FieldValue.increment(amar),
                                'tarjetas_rojas': FieldValue.increment(roj),
                              }, SetOptions(merge: true));
                            }
                            await batch.commit();
                            // Marcar partido como agregado
                            await docRef.update({'aggregated': true});
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error aplicando agregados: $e')));
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
                      }
                    }
                    aController.dispose();
                    bController.dispose();
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.people),
                        tooltip: 'Convocatorias y disponibilidad',
                        onPressed: () async {
                          final matchId = snapshot.data!.docs[index].id;
                          // Determinar si el usuario actual es coach
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                          bool isCoach = false;
                          if (currentUserId != null) {
                            try {
                              final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
                              final coachId = teamDoc.data()?['coachId'] as String?;
                              isCoach = (coachId == currentUserId);
                            } catch (_) {}
                          }
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MatchAvailabilityPage(
                                  teamId: teamId,
                                  matchId: matchId,
                                  isCoach: isCoach,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stacked_bar_chart),
                        tooltip: 'Estadísticas',
                        onPressed: () {
                          final matchId = snapshot.data!.docs[index].id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchStatsEditor(teamId: teamId, matchId: matchId),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        tooltip: 'Eliminar partido',
                        onPressed: () async {
                          final matchRef = snapshot.data!.docs[index].reference;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar partido'),
                              content: const Text('¿Eliminar este partido del historial? Esta acción puede revertir estadísticas agregadas.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (confirm != true) return;

                          try {
                            final matchData = (snapshot.data!.docs[index].data() as Map<String, dynamic>);
                            final aggregated = (matchData['aggregated'] ?? false) as bool;

                            if (aggregated) {
                              final statsSnap = await matchRef.collection('stats').get();
                              final batch = FirebaseFirestore.instance.batch();
                              for (final s in statsSnap.docs) {
                                final sd = s.data();
                                final pid = s.id;
                                final goles = (sd['goles'] ?? 0) as int;
                                final asist = (sd['asistencias'] ?? 0) as int;
                                final minutos = (sd['minutos'] ?? 0) as int;
                                final amar = (sd['amarillas'] ?? 0) as int;
                                final roj = (sd['rojas'] ?? 0) as int;
                                final convocado = (sd['convocado'] ?? true) as bool;
                                if (!convocado) continue;

                                final playerRef = FirebaseFirestore.instance.collection('teams').doc(teamId).collection('players').doc(pid);
                                batch.set(playerRef, {
                                  'goles': FieldValue.increment(-goles),
                                  'asistencias': FieldValue.increment(-asist),
                                  'minutos': FieldValue.increment(-minutos),
                                  'partidos': FieldValue.increment(- (minutos > 0 ? 1 : 0)),
                                  'tarjetas_amarillas': FieldValue.increment(-amar),
                                  'tarjetas_rojas': FieldValue.increment(-roj),
                                }, SetOptions(merge: true));
                              }
                              await batch.commit();
                            }

                            final statsToDelete = await matchRef.collection('stats').get();
                            final batchDel = FirebaseFirestore.instance.batch();
                            for (final s in statsToDelete.docs) {
                              batchDel.delete(s.reference);
                            }
                            await batchDel.commit();
                            await matchRef.delete();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partido eliminado')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando: $e')));
                            }
                          }
                        },
                      ),
                    ],
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