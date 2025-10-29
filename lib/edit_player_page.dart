import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPlayerPage extends StatefulWidget {
  final String teamId;
  final String playerId;
  final Map<String, dynamic> playerData;

  const EditPlayerPage({
    super.key,
    required this.teamId,
    required this.playerId,
    required this.playerData,
  });

  @override
  State<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends State<EditPlayerPage> {
  late TextEditingController golesController;
  late TextEditingController asistenciasController;
  late TextEditingController posicionController;

  @override
  void initState() {
    super.initState();
    golesController = TextEditingController(text: widget.playerData['goles']?.toString() ?? '0');
    asistenciasController = TextEditingController(text: widget.playerData['asistencias']?.toString() ?? '0');
    posicionController = TextEditingController(text: widget.playerData['posicion'] ?? '');
  }

  Future<void> _guardarCambios() async {
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('players')
        .doc(widget.playerId)
        .update({
      'goles': int.tryParse(golesController.text) ?? 0,
      'asistencias': int.tryParse(asistenciasController.text) ?? 0,
      'posicion': posicionController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Datos actualizados correctamente")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar jugador: ${widget.playerData['name']}"),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: posicionController,
              decoration: const InputDecoration(labelText: "Posición"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: golesController,
              decoration: const InputDecoration(labelText: "Goles"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: asistenciasController,
              decoration: const InputDecoration(labelText: "Asistencias"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarCambios,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
              child: const Text("Guardar cambios"),
            ),
          ],
        ),
      ),
    );
  }
}
