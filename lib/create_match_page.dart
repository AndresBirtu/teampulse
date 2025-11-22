import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateMatchPage extends StatefulWidget {
  final String teamId;
  const CreateMatchPage({required this.teamId, super.key});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();
  DateTime? _matchDate;
  bool _played = false;
  final TextEditingController _golesAController = TextEditingController(text: '0');
  final TextEditingController _golesBController = TextEditingController(text: '0');

  String? _teamName;

  @override
  void initState() {
    super.initState();
    // Prefill team A from teams/{teamId}.name if available
    FirebaseFirestore.instance.collection('teams').doc(widget.teamId).get().then((doc) {
      final name = doc.data()?['name'] as String?;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _teamName = name;
          _teamAController.text = name;
        });
      }
    }).catchError((_) {});
  }

  Future<void> _saveMatch() async {
    if (_teamAController.text.isEmpty ||
        _teamBController.text.isEmpty ||
        _matchDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Crear el documento del partido y obtener la referencia
      final matchRef = await FirebaseFirestore.instance
          .collection("teams")
          .doc(widget.teamId)
          .collection("matches")
          .add({
        "teamA": _teamAController.text.trim(),
        "teamB": _teamBController.text.trim(),
        "date": Timestamp.fromDate(_matchDate!),
        "createdAt": FieldValue.serverTimestamp(),
        "played": _played,
        "convocados": [], // Lista vacía de convocados, el entrenador los añadirá
        if (_played) "golesTeamA": int.tryParse(_golesAController.text) ?? 0,
        if (_played) "golesTeamB": int.tryParse(_golesBController.text) ?? 0,
      });

      // Generar automáticamente la hoja de stats (un doc por jugador en matches/{matchId}/stats/{playerId})
      try {
        final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).get();
        final teamCoachId = teamDoc.data()?['coachId'] as String?;

        final playersSnap = await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('players')
            .get();

        if (playersSnap.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final p in playersSnap.docs) {
            final playerData = p.data() as Map<String, dynamic>;
            final statRef = matchRef.collection('stats').doc(p.id);
            // Determinar si es entrenador: mirar 'role', 'isCoach' flag, o comparar con team.coachId
            final role = playerData['role'] as String?;
            final isCoachFlag = playerData['isCoach'] as bool? ?? false;
            final bool isCoach = isCoachFlag || 
                                 (role != null && (role.toLowerCase() == 'coach' || role.toLowerCase() == 'entrenador')) || 
                                 (teamCoachId != null && teamCoachId == p.id);
            batch.set(statRef, {
              'playerId': p.id,
              'playerName': playerData['name'] ?? '',
              'minutos': 0,
              'goles': 0,
              'asistencias': 0,
              'amarillas': 0,
              'rojas': 0,
              'titular': false,
              // marcar como convocado por defecto y propagar si es entrenador
              'convocado': true,
              'isCoach': isCoach,
            });
          }
          await batch.commit();
        }
      } catch (e) {
        // No bloqueamos la creación del partido si falla la hoja de stats,
        // pero avisamos al usuario para que lo revise.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Partido guardado, pero fallo al generar hoja de stats: $e')));
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Partido guardado correctamente")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear partido"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _teamAController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Equipo A",
                        border: const OutlineInputBorder(),
                        suffixIcon: _teamName == null ? const SizedBox.shrink() : const Icon(Icons.home),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teamBController,
                      decoration: const InputDecoration(labelText: "Equipo B", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _played,
                      onChanged: (v) => setState(() => _played = v),
                      title: const Text('Marcado como jugado'),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    if (_played)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _golesAController,
                              decoration: const InputDecoration(labelText: "Goles Equipo A", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _golesBController,
                              decoration: const InputDecoration(labelText: "Goles Equipo B", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _matchDate == null
                        ? "Selecciona la fecha"
                        : "${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year} ${_matchDate!.hour}:${_matchDate!.minute.toString().padLeft(2, '0')}",
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _matchDate = DateTime(
                              date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                  child: const Text("Seleccionar fecha"),
                )
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMatch,
                child: const Text("Guardar partido", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
