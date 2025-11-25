import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrainingsPage extends StatelessWidget {
  final String teamId;
  const TrainingsPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final trainingsStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('trainings')
        .orderBy('date', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamientos'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: trainingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text('No hay entrenamientos. Crea uno usando el botón +', style: Theme.of(context).textTheme.bodyMedium));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              final formatted = date != null ? '${date.day}/${date.month}/${date.year}' : 'Sin fecha';
              final notes = data['notes'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('Entrenamiento - $formatted', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditTrainingPage(teamId: teamId, trainingId: d.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const SizedBox.shrink();
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          final role = userData?['role'] ?? '';
          
          // Solo mostrar botón de crear entrenamiento si es entrenador
          if (role.toLowerCase() != 'entrenador') return const SizedBox.shrink();
          
          return FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditTrainingPage(teamId: teamId)),
              );
            },
          );
        },
      ),
    );
  }
}

class EditTrainingPage extends StatefulWidget {
  final String teamId;
  final String? trainingId;

  const EditTrainingPage({super.key, required this.teamId, this.trainingId});

  @override
  State<EditTrainingPage> createState() => _EditTrainingPageState();
}

class _EditTrainingPageState extends State<EditTrainingPage> {
  DateTime _date = DateTime.now();
  final TextEditingController _notesCtrl = TextEditingController();
  Map<String, dynamic> _playersState = {}; // playerId -> {presence, punctuality, fitness, name}
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    if (widget.trainingId != null) _loadExisting();
  }

  Future<void> _loadPlayers() async {
    final snap = await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('players').get();
    final map = <String, dynamic>{};
    for (var doc in snap.docs) {
      final d = doc.data();
      map[doc.id] = {
        'name': d['name'] ?? 'Jugador',
        // default: assume present and on-time for fast marking
        'presence': 'present',
        'punctuality': 'on-time',
        'fitness': 3,
        'note': '',
        // extended metrics: 1 (bad/red), 2 (medium/orange), 3 (good/green)
        'intensity': 3,
        'technique': 3,
        'assistance': 3,
        'attitude': 3,
        'injuryRisk': 1,
      };
    }
    setState(() => _playersState = map);
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('trainings').doc(widget.trainingId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _date = (data['date'] as Timestamp).toDate();
      _notesCtrl.text = data['notes'] ?? '';
      final players = data['players'] as Map<String, dynamic>? ?? {};
      for (var e in players.entries) {
        _playersState[e.key] = {
          'name': (players[e.key]['name'] ?? _playersState[e.key]?['name']) ?? 'Jugador',
          'presence': players[e.key]['presence'] ?? 'absent',
          'punctuality': players[e.key]['punctuality'] ?? 'on-time',
          'fitness': players[e.key]['fitness'] ?? 3,
        };
      }
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final playersMap = <String, dynamic>{};
      _playersState.forEach((k, v) {
        playersMap[k] = {
          'name': v['name'],
          'presence': v['presence'],
          'punctuality': v['punctuality'],
          'fitness': v['fitness'],
          'note': v['note'] ?? '',
        };
      });

      final data = {
        'date': Timestamp.fromDate(_date),
        'notes': _notesCtrl.text.trim(),
        'players': playersMap,
        'completed': true, // mark training as completed when saved
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final col = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('trainings');
      if (widget.trainingId == null) {
        await col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await col.doc(widget.trainingId).set(data, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _metricChip(BuildContext context, Map<String, dynamic> p, String label, int value) {
    final keyMap = {
      'Físico': 'fitness',
      'Técnica': 'technique',
      'Actitud': 'attitude',
      'Riesgo': 'injuryRisk',
    };
    final key = keyMap[label] ?? label.toLowerCase();
    int v = (p[key] ?? value) as int;

    Color chipColor;
    if (label == 'Riesgo') {
      if (v <= 1) {
        chipColor = Colors.green;
      } else if (v == 2) {
        chipColor = Colors.orange;
      } else {
        chipColor = Colors.red;
      }
    } else {
      if (v <= 1) {
        chipColor = Colors.red;
      } else if (v == 2) {
        chipColor = Colors.orange;
      } else {
        chipColor = Colors.green;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          int cur = (p[key] ?? value) as int;
          cur = (cur % 3) + 1;
          p[key] = cur;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor.withOpacity(0.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'Riesgo'
                  ? (v == 1 ? Icons.health_and_safety : (v == 2 ? Icons.report_problem : Icons.warning))
                  : (v == 1 ? Icons.thumb_down : (v == 2 ? Icons.remove_circle : Icons.thumb_up)),
              size: 16,
              color: chipColor,
            ),
            const SizedBox(width: 6),
            Text('$label', style: TextStyle(color: chipColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trainingId == null ? 'Crear entrenamiento' : 'Editar entrenamiento'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _playersState.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Fecha: ${_date.day}/${_date.month}/${_date.year}'),
                    trailing: TextButton(onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) setState(() => _date = picked);
                    }, child: const Text('Cambiar')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notas generales'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Jugadores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._playersState.entries.map((e) {
                    final p = e.value as Map<String, dynamic>;
                    final presence = (p['presence'] ?? 'present') as String;
                    final punctuality = (p['punctuality'] ?? 'on-time') as String;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if ((p['presence'] ?? 'present') == 'absent') {
                            p['presence'] = 'present';
                            p['punctuality'] = 'on-time';
                          } else {
                            p['punctuality'] = (p['punctuality'] == 'on-time') ? 'late' : 'on-time';
                          }
                        });
                      },
                      onDoubleTap: () {
                        setState(() {
                          if ((p['presence'] ?? 'present') == 'absent') {
                            p['presence'] = 'present';
                            p['punctuality'] = 'on-time';
                          } else {
                            p['presence'] = 'absent';
                            p['punctuality'] = 'absent';
                          }
                        });
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fila superior: nombre, estado, nota
                              Row(
                                children: [
                                  Expanded(child: Text(p['name'] ?? 'Jugador', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          presence == 'absent'
                                              ? Icons.close
                                              : (punctuality == 'on-time' ? Icons.check_circle : Icons.access_time),
                                          color: presence == 'absent'
                                              ? Colors.grey
                                              : (punctuality == 'on-time' ? Colors.green : Colors.orange),
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(presence == 'absent' ? 'Ausente' : (punctuality == 'on-time' ? 'Puntual' : 'Tarde'), style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.note, color: (p['note'] ?? '').toString().isNotEmpty ? Theme.of(context).primaryColor : Colors.black54),
                                    onPressed: () async {
                                      final text = await showDialog<String?>(
                                        context: context,
                                        builder: (ctx) {
                                          final ctrl = TextEditingController(text: p['note'] ?? '');
                                          return AlertDialog(
                                            title: const Text('Nota para jugador'),
                                            content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Agregar nota...')),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Guardar')),
                                            ],
                                          );
                                        },
                                      );
                                      if (text != null) setState(() => p['note'] = text);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Métricas: Físico, Técnica, Actitud, Riesgo
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _metricChip(context, p, 'Físico', p['fitness'] ?? 3),
                                  _metricChip(context, p, 'Técnica', p['technique'] ?? 3),
                                  _metricChip(context, p, 'Actitud', p['attitude'] ?? 3),
                                  _metricChip(context, p, 'Riesgo', p['injuryRisk'] ?? 1),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
