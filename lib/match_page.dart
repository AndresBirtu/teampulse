import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_match_page.dart';
import 'match_stats_editor.dart';
import 'match_availability_page.dart';
import 'theme/app_colors.dart';

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
        title: const Text("Gestión de partidos", style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const SizedBox.shrink();
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          final role = userData?['role'] ?? '';
          
          // Solo mostrar botón de crear partido si es entrenador
          if (role.toLowerCase() != 'entrenador') return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            elevation: 6,
            icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
            label: const Text(
              'Nuevo Partido',
              style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateMatchPage(teamId: teamId)),
              );
            },
          );
        },
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

              final isPlayed = (match['played'] ?? false) as bool;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 4,
                shadowColor: isPlayed ? AppColors.matchPlayed.withOpacity(0.3) : AppColors.matchColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isPlayed 
                        ? LinearGradient(
                            colors: [AppColors.matchPlayed.withOpacity(0.08), AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [AppColors.matchColor.withOpacity(0.08), AppColors.primaryLight.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isPlayed ? null : AppColors.matchGradient,
                        color: isPlayed ? AppColors.matchPlayed : null,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isPlayed ? AppColors.matchPlayed.withOpacity(0.3) : AppColors.matchColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sports_soccer, color: AppColors.textOnPrimary, size: 28),
                    ),
                    title: Text(
                      "$teamA vs $teamB", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPlayed ? AppColors.textSecondary : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(formattedDate, style: TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        if (isPlayed) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.matchPlayed.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.emoji_events, size: 16, color: AppColors.goals),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Resultado: ${(match['golesTeamA'] ?? 0).toString()} - ${(match['golesTeamB'] ?? 0).toString()}',
                                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                                    activeColor: AppColors.primary,
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
                  trailing: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, userSnap) {
                      final isCoach = userSnap.hasData &&
                          (userSnap.data!.data() as Map<String, dynamic>?)?['role']?.toString().toLowerCase() == 'entrenador';

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        IconButton(
                          icon: const Icon(Icons.people),
                          iconSize: 20,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          tooltip: 'Convocatorias y disponibilidad',
                          onPressed: () async {
                              final matchId = snapshot.data!.docs[index].id;
                              // Determinar si el usuario actual es coach
                              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                              bool isCoachCheck = false;
                              if (currentUserId != null) {
                                try {
                                  final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
                                  final coachId = teamDoc.data()?['coachId'] as String?;
                                  isCoachCheck = (coachId == currentUserId);
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
                          if (isCoach) ...[
                            IconButton(
                              icon: const Icon(Icons.stacked_bar_chart),
                              iconSize: 20,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
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
                              icon: const Icon(Icons.delete_forever, color: AppColors.error),
                              iconSize: 20,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
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
                        ],
                      );
                    },
                  ),
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