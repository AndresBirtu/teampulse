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

  Future<void> _saveMatch() async {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || _matchDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos"), backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("teams")
        .doc(widget.teamId)
        .collection("matches")
        .add({
      "teamA": _teamAController.text.trim(),
      "teamB": _teamBController.text.trim(),
      "date": Timestamp.fromDate(_matchDate!),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear partido"),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _teamAController,
              decoration: const InputDecoration(labelText: "Equipo A"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamBController,
              decoration: const InputDecoration(labelText: "Equipo B"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_matchDate == null
                      ? "Selecciona la fecha"
                      : "${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year} ${_matchDate!.hour}:${_matchDate!.minute.toString().padLeft(2,'0')}"),
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
                          _matchDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                child: const Text("Guardar partido"),
              ),
            )
          ],
        ),
      ),
    );
  }
}