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
      await FirebaseFirestore.instance
          .collection("teams")
          .doc(widget.teamId)
          .collection("matches")
          .add({
        "teamA": _teamAController.text.trim(),
        "teamB": _teamBController.text.trim(),
        "date": Timestamp.fromDate(_matchDate!),
        "createdAt": FieldValue.serverTimestamp(),
              "played": _played,
              if (_played) "golesTeamA": int.tryParse(_golesAController.text) ?? 0,
              if (_played) "golesTeamB": int.tryParse(_golesBController.text) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Partido guardado correctamente")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
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
