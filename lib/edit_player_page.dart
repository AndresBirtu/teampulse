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
  late TextEditingController partidosController;
  late TextEditingController minutosController;
  late TextEditingController amarillasController;
  late TextEditingController rojasController;

  @override
  void initState() {
    super.initState();
    golesController =
        TextEditingController(text: widget.playerData['goles']?.toString() ?? '0');
    asistenciasController =
        TextEditingController(text: widget.playerData['asistencias']?.toString() ?? '0');
    posicionController =
        TextEditingController(text: widget.playerData['posicion'] ?? '');
    partidosController =
        TextEditingController(text: widget.playerData['partidos']?.toString() ?? '0');
    minutosController =
        TextEditingController(text: widget.playerData['minutos']?.toString() ?? '0');
    amarillasController =
        TextEditingController(text: widget.playerData['tarjetas_amarillas']?.toString() ?? '0');
    rojasController =
        TextEditingController(text: widget.playerData['tarjetas_rojas']?.toString() ?? '0');
  }

  Future<void> _guardarCambios() async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .doc(widget.playerId)
          .set({
        'goles': int.tryParse(golesController.text) ?? 0,
        'asistencias': int.tryParse(asistenciasController.text) ?? 0,
        'posicion': posicionController.text,
        'partidos': int.tryParse(partidosController.text) ?? 0,
        'minutos': int.tryParse(minutosController.text) ?? 0,
        'tarjetas_amarillas': int.tryParse(amarillasController.text) ?? 0,
        'tarjetas_rojas': int.tryParse(rojasController.text) ?? 0,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos actualizados correctamente")),
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
        title: Text("Editar jugador: ${widget.playerData['name']}"),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: posicionController,
                  decoration: const InputDecoration(labelText: "Posición", border: OutlineInputBorder()),
                ),
            const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextField(
                  controller: partidosController,
                  decoration: const InputDecoration(labelText: "Partidos jugados", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
            const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextField(
                  controller: minutosController,
                  decoration: const InputDecoration(labelText: "Minutos jugados", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
            const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextField(
                  controller: golesController,
                  decoration: const InputDecoration(labelText: "Goles", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
            const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextField(
                  controller: asistenciasController,
                  decoration: const InputDecoration(labelText: "Asistencias", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
            const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextField(
                  controller: amarillasController,
                  decoration: const InputDecoration(labelText: "Tarjetas amarillas", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
            const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextField(
                  controller: rojasController,
                  decoration: const InputDecoration(labelText: "Tarjetas rojas", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Guardar cambios", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
