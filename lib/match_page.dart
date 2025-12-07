import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_match_page.dart';
import 'match_stats_editor.dart';
import 'match_availability_page.dart';
import 'lineup_builder_page.dart';
import 'theme/app_themes.dart';

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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final primaryDark = context.primaryDarkColor;
    final onPrimary = colorScheme.onPrimary;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    final outline = colorScheme.outline;
    final surface = colorScheme.surface;
    final accent = colorScheme.secondary;
    final errorColor = colorScheme.error;

    final matchesStream = FirebaseFirestore.instance
        .collection("teams")
        .doc(teamId)
        .collection("matches")
        .orderBy("date", descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gestión de partidos",
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
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
          
          return FloatingActionButton(
            backgroundColor: primary,
            elevation: 6,
            child: Icon(Icons.add, color: onPrimary, size: 28),
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
              final matchDoc = matches[index];
              final match = matchDoc.data() as Map<String, dynamic>;
              final matchId = matchDoc.id;
              final matchRef = matchDoc.reference;
              final teamA = match["teamA"] ?? "Desconocido";
              final teamB = match["teamB"] ?? "Desconocido";
              final date = (match["date"] as Timestamp?)?.toDate();
              final matchNote = (match['note'] ?? '').toString().trim();

              final formattedDate = date != null
                  ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                  : "Sin fecha";

              final isPlayed = (match['played'] ?? false) as bool;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 4,
                shadowColor: (isPlayed ? outline : primary).withOpacity(0.25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? LinearGradient(
                            colors: [outline.withOpacity(0.15), surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [primary.withOpacity(0.08), primary.withOpacity(0.02)],
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
                        gradient: isPlayed ? null : context.primaryGradient,
                        color: isPlayed ? outline : null,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPlayed ? outline : primary).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.sports_soccer, color: isPlayed ? primary : onPrimary, size: 26),
                    ),
                    title: Text(
                      "$teamA vs $teamB", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPlayed ? textSecondary : textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formattedDate,
                                style: TextStyle(color: textSecondary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isPlayed) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events, size: 16, color: primaryDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${match['golesTeamA'] ?? 0} - ${match['golesTeamB'] ?? 0}',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (matchNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note_alt_outlined, size: 16, color: accent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  matchNote,
                                  style: TextStyle(color: textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, userSnap) {
                            final isCoach = userSnap.hasData &&
                                (userSnap.data!.data() as Map<String, dynamic>?)?['role']?.toString().toLowerCase() == 'entrenador';

                            return Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _matchActionChip(
                                  context: context,
                                  icon: Icons.people,
                                  tooltip: 'Convocatorias y disponibilidad',
                                  color: primary,
                                  onTap: () {
                                    if (!context.mounted) return;
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
                                  },
                                ),
                                if (isCoach)
                                  _matchActionChip(
                                    context: context,
                                    icon: Icons.stacked_bar_chart,
                                    tooltip: 'Estadísticas',
                                    color: accent,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MatchStatsEditor(teamId: teamId, matchId: matchId),
                                        ),
                                      );
                                    },
                                  ),
                                if (isCoach)
                                  _matchActionChip(
                                    context: context,
                                    icon: Icons.sports_soccer_outlined,
                                    tooltip: 'Formaciones',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LineupBuilderPage(teamId: teamId, matchId: matchId),
                                        ),
                                      );
                                    },
                                  ),
                                if (isCoach)
                                  _matchActionChip(
                                    context: context,
                                    icon: Icons.note_alt_outlined,
                                    tooltip: 'Anotaciones del partido',
                                    color: accent,
                                    onTap: () => _showMatchNoteEditor(context, matchRef, matchNote),
                                  ),
                                if (isCoach)
                                  _matchActionChip(
                                    context: context,
                                    icon: Icons.delete_forever,
                                    tooltip: 'Eliminar partido',
                                    color: errorColor,
                                    onTap: () async {
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
                                        final aggregated = (match['aggregated'] ?? false) as bool;

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

                                            final playerRef = FirebaseFirestore.instance
                                                .collection('teams')
                                                .doc(teamId)
                                                .collection('players')
                                                .doc(pid);
                                            batch.set(playerRef, {
                                              'goles': FieldValue.increment(-goles),
                                              'asistencias': FieldValue.increment(-asist),
                                              'minutos': FieldValue.increment(-minutos),
                                              'partidos': FieldValue.increment(-(minutos > 0 ? 1 : 0)),
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
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(content: Text('Partido eliminado')));
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(content: Text('Error eliminando: $e')));
                                        }
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  onTap: () async {
                    // Abrir diálogo para editar resultado/marcar jugado
                    final docRef = matchRef;
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
                                    activeColor: primary,
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _matchActionChip({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: resolvedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: resolvedColor, size: 20),
        ),
      ),
    );
  }

  Future<void> _showMatchNoteEditor(
    BuildContext context,
    DocumentReference matchRef,
    String currentNote,
  ) async {
    final controller = TextEditingController(text: currentNote);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anotaciones del partido',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Llegar 30 min antes, traer identificación...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(sheetCtx, ''),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Limpiar nota'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx, controller.text.trim()),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await matchRef.update({
        'note': result,
        'noteUpdatedAt': FieldValue.serverTimestamp(),
        'noteUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anotaciones actualizadas')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar las notas: $e')),
      );
    }
  }
}