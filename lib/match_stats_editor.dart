import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchStatsEditor extends StatefulWidget {
  final String teamId;
  final String matchId;
  final int? matchDurationMinutes; // Si null, se asume 90 minutos

  const MatchStatsEditor({
    required this.teamId,
    required this.matchId,
    this.matchDurationMinutes,
    super.key,
  });

  @override
  State<MatchStatsEditor> createState() => _MatchStatsEditorState();
}

class _MatchStatsEditorState extends State<MatchStatsEditor> {
  late final int _matchDuration = widget.matchDurationMinutes ?? 90;
  final Map<String, Map<String, dynamic>> _statsCache = {};
  bool _isSaving = false;
  String? _teamCoachId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas del partido'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('matches')
            .doc(widget.matchId)
            .collection('stats')
            .orderBy('playerId')
            .snapshots(),
        builder: (context, snapshot) {
          // Asegurar que tenemos el coachId del equipo
          if (_teamCoachId == null) {
            FirebaseFirestore.instance.collection('teams').doc(widget.teamId).get().then((d) {
              if (d.exists) {
                final data = d.data();
                setState(() {
                  _teamCoachId = (data?['coachId'] as String?) ?? null;
                });
              }
            }).catchError((_) {});
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!.docs;
          if (stats.isEmpty) {
            return const Center(child: Text('No hay jugadores en la hoja de estadísticas'));
          }

          // Agrupar: titulares y suplentes
          final titulares = <QueryDocumentSnapshot>[];
          final suplentes = <QueryDocumentSnapshot>[];

          for (final stat in stats) {
            final isTitular = stat['titular'] as bool? ?? false;
            if (isTitular) {
              titulares.add(stat);
            } else {
              suplentes.add(stat);
            }
          }

          return ListView(
            children: [
              if (titulares.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Titulares (${titulares.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ..._buildPlayersList(titulares),
              ],
              if (suplentes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Suplentes (${suplentes.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ..._buildPlayersList(suplentes),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _applyAggregates,
                            child: const Text('Aplicar a jugadores', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: _isSaving ? null : _forceReapplyAggregates,
                            child: const Text('Forzar re-aplicar', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAll,
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Future<void> _tryAggregateIfNeeded() async {
    try {
      final matchRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId);
      final matchSnap = await matchRef.get();
      final matchData = matchSnap.data() as Map<String, dynamic>? ?? {};
      final played = (matchData['played'] ?? false) as bool;
      final aggregated = (matchData['aggregated'] ?? false) as bool;
      if (!played || aggregated) return;

      final statsSnap = await matchRef.collection('stats').get();
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

        final playerRef = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('players').doc(pid);
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
      await matchRef.update({'aggregated': true});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estadísticas agregadas a los jugadores')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al agregar estadísticas: $e')));
    }
  }

  Future<void> _applyAggregates() async {
    setState(() => _isSaving = true);
    try {
      final matchRef = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('matches').doc(widget.matchId);
      final matchSnap = await matchRef.get();
      final matchData = matchSnap.data() ?? {};
      final aggregated = (matchData['aggregated'] ?? false) as bool;
      if (aggregated) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya se aplicaron las estadísticas a los jugadores')));
        return;
      }
      // aplicar
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

        final playerRef = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('players').doc(pid);
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
      await matchRef.update({'aggregated': true});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aplicadas estadísticas a jugadores')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error aplicando: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _revertAggregates() async {
    setState(() => _isSaving = true);
    try {
      final matchRef = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('matches').doc(widget.matchId);
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

        final playerRef = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('players').doc(pid);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revertidas estadísticas en players')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error revirtiendo: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _forceReapplyAggregates() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forzar re-aplicar'),
        content: const Text('Esto intentará revertir y volver a aplicar las estadísticas a los jugadores. Asegúrate de tener copia de seguridad.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (confirm != true) return;
    await _revertAggregates();
    await _applyAggregates();
  }

  List<Widget> _buildPlayersList(List<QueryDocumentSnapshot> playerStats) {
    return playerStats.map((stat) {
      final playerId = stat.id;
      final playerName = stat['playerName'] as String? ?? 'Jugador';
      final isTitular = stat['titular'] as bool? ?? false;
      final goles = stat['goles'] as int? ?? 0;
      final asistencias = stat['asistencias'] as int? ?? 0;
      final amarillas = stat['amarillas'] as int? ?? 0;
      final rojas = stat['rojas'] as int? ?? 0;
      final minutos = stat['minutos'] as int? ?? 0;
      final isConvocado = stat['convocado'] as bool? ?? true;
      final isCoachStat = stat['isCoach'] as bool?;

      Widget cardWidget() {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre, convocation toggle y titular/suplente
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        playerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Convocado'),
                        Switch(
                          value: isConvocado,
                          onChanged: (v) {
                            // Si desconvocamos, ponemos minutos a 0 y no titular
                            if (!v) {
                              _updateStat(playerId, 'minutos', 0);
                              _toggleTitular(playerId, false);
                            }
                            // actualizar caché local y firestore con booleano
                            setState(() {
                              _statsCache[playerId] ??= {};
                              _statsCache[playerId]!['convocado'] = v;
                            });
                            FirebaseFirestore.instance
                                .collection('teams')
                                .doc(widget.teamId)
                                .collection('matches')
                                .doc(widget.matchId)
                                .collection('stats')
                                .doc(playerId)
                                .set({'convocado': v}, SetOptions(merge: true));
                            setState(() {});
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(isTitular ? '11 Inicial' : 'Suplente'),
                          backgroundColor: isTitular ? Colors.green[200] : Colors.grey[300],
                          onDeleted: isConvocado ? () => _toggleTitular(playerId, !isTitular) : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Goles y Asistencias (botones + y -)
                Opacity(
                  opacity: isConvocado ? 1.0 : 0.5,
                  child: AbsorbPointer(
                    absorbing: !isConvocado,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatControl('⚽ Goles', goles, () => _updateStat(playerId, 'goles', goles + 1), () => _updateStat(playerId, 'goles', (goles - 1).clamp(0, 999))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatControl('🎁 Asist.', asistencias, () => _updateStat(playerId, 'asistencias', asistencias + 1), () => _updateStat(playerId, 'asistencias', (asistencias - 1).clamp(0, 999))),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tarjetas
                Row(
                  children: [
                    Expanded(
                      child: _buildCardSelector(playerId, amarillas, rojas),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Minutos (Slider)
                Opacity(
                  opacity: isConvocado ? 1.0 : 0.5,
                  child: AbsorbPointer(
                    absorbing: !isConvocado,
                    child: _buildMinutesSlider(playerId, minutos),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Si el stat ya declara isCoach = true, o coincide con coachId del equipo, ocultar.
      if (isCoachStat == true) return const SizedBox.shrink();
      if (_teamCoachId != null && playerId == _teamCoachId) return const SizedBox.shrink();

      // Si no está declarado en el stat, miramos el documento del jugador por si es coach
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('players').doc(playerId).get(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            // Mientras cargamos, mostramos el card (permitir edición rápida)
            return cardWidget();
          }
          final pdoc = snap.data;
          final pdata = pdoc?.data() as Map<String, dynamic>?;
          final playerIsCoachFlag = pdata?['isCoach'] as bool? ?? false;
          final playerRole = (pdata?['role'] as String?)?.toLowerCase();
          final playerIsCoach = playerIsCoachFlag || (playerRole == 'coach');
          if (playerIsCoach) return const SizedBox.shrink();
          return cardWidget();
        },
      );
    }).toList();
  }

  Widget _buildStatControl(String label, int value, VoidCallback onAdd, VoidCallback onSubtract) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: onSubtract,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelector(String playerId, int amarillas, int rojas) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text('Tarjetas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(amarillas.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateStat(playerId, 'amarillas', amarillas + 1),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(rojas.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateStat(playerId, 'rojas', rojas + 1),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesSlider(String playerId, int minutos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('⏱ Minutos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('$minutos min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: minutos.toDouble(),
          min: 0,
          max: _matchDuration.toDouble(),
          divisions: _matchDuration,
          label: '$minutos',
          onChanged: (val) => _updateStat(playerId, 'minutos', val.toInt()),
        ),
      ],
    );
  }

  void _updateStat(String playerId, String field, int value) {
    setState(() {
      _statsCache[playerId] ??= {};
      _statsCache[playerId]![field] = value;
    });

    // Guardar en Firestore de manera no bloqueante
    FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('matches')
        .doc(widget.matchId)
        .collection('stats')
        .doc(playerId)
        .set({field: value}, SetOptions(merge: true))
        .catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
      }
    });
  }

  void _toggleTitular(String playerId, bool isTitular) {
    setState(() {
      _statsCache[playerId] ??= {};
      _statsCache[playerId]!['titular'] = isTitular;
      // Si se marca como titular y no tiene minutos, asignarle la duración del partido
      if (isTitular && (_statsCache[playerId]!['minutos'] as int? ?? 0) == 0) {
        _statsCache[playerId]!['minutos'] = _matchDuration;
      }
    });

    FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('matches')
        .doc(widget.matchId)
        .collection('stats')
        .doc(playerId)
        .set({
          'titular': isTitular,
          if (isTitular) 'minutos': _matchDuration,
        }, SetOptions(merge: true))
        .catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      if (_statsCache.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        _statsCache.forEach((playerId, updates) {
          final statRef = FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('matches')
              .doc(widget.matchId)
              .collection('stats')
              .doc(playerId);
          batch.set(statRef, updates, SetOptions(merge: true));
        });
        await batch.commit();
        _statsCache.clear();
      }

      // Después de guardar stats, si el partido ya está marcado como jugado y aún no
      // se han agregado las estadísticas al documento `players`, aplicarlas ahora.
      await _tryAggregateIfNeeded();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
