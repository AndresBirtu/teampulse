import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/players/domain/entities/player_update.dart';
import 'package:teampulse/features/players/presentation/providers/player_repository_provider.dart';

class EditPlayerPage extends ConsumerStatefulWidget {
  const EditPlayerPage({
    super.key,
    required this.teamId,
    required this.playerId,
    required this.playerData,
  });

  final String teamId;
  final String playerId;
  final Map<String, dynamic> playerData;

  @override
  ConsumerState<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends ConsumerState<EditPlayerPage> {
  late TextEditingController golesController;
  late TextEditingController asistenciasController;
  late TextEditingController partidosController;
  late TextEditingController minutosController;
  late TextEditingController amarillasController;
  late TextEditingController rojasController;
  late String selectedPosicion;
  late List<String> posiciones;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    golesController = TextEditingController(text: _initialValue('goles'));
    asistenciasController = TextEditingController(text: _initialValue('asistencias'));
    partidosController = TextEditingController(text: _initialValue('partidos'));
    minutosController = TextEditingController(text: _initialValue('minutos'));
    amarillasController = TextEditingController(text: _initialValue('tarjetas_amarillas'));
    rojasController = TextEditingController(text: _initialValue('tarjetas_rojas'));

    posiciones = ['Portero', 'Cierre', 'Pivot', 'Ala'];
    final posicionGuardada = (widget.playerData['posicion'] as String?)?.trim();
    if (posicionGuardada != null && posicionGuardada.isNotEmpty && !posiciones.contains(posicionGuardada)) {
      posiciones.add(posicionGuardada);
    }
    selectedPosicion = posicionGuardada?.isNotEmpty == true ? posicionGuardada! : 'Ala';
  }

  @override
  void dispose() {
    golesController.dispose();
    asistenciasController.dispose();
    partidosController.dispose();
    minutosController.dispose();
    amarillasController.dispose();
    rojasController.dispose();
    super.dispose();
  }

  String _initialValue(String key) => widget.playerData[key]?.toString() ?? '0';

  int _parseInt(String value) => int.tryParse(value) ?? 0;

  Future<void> _guardarCambios() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repository = ref.read(playerRepositoryProvider);
    final update = PlayerUpdate(
      position: selectedPosicion,
      minutes: _parseInt(minutosController.text),
      goals: _parseInt(golesController.text),
      assists: _parseInt(asistenciasController.text),
      matches: _parseInt(partidosController.text),
      yellowCards: _parseInt(amarillasController.text),
      redCards: _parseInt(rojasController.text),
    );

    try {
      await repository.updatePlayerStats(
        teamId: widget.teamId,
        playerId: widget.playerId,
        update: update,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerName = widget.playerData['name'] ?? 'Jugador';
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar jugador: $playerName'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPosicion,
                  decoration: const InputDecoration(
                    labelText: 'Posición',
                    border: OutlineInputBorder(),
                  ),
                  items: posiciones
                      .map((position) => DropdownMenuItem(value: position, child: Text(position)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedPosicion = value ?? selectedPosicion),
                ),
                const SizedBox(height: 10),
                _StatField(
                  controller: minutosController,
                  label: 'Minutos jugados',
                ),
                const SizedBox(height: 10),
                _StatField(
                  controller: golesController,
                  label: 'Goles',
                ),
                const SizedBox(height: 10),
                _StatField(
                  controller: asistenciasController,
                  label: 'Asistencias',
                ),
                const SizedBox(height: 10),
                _StatField(
                  controller: partidosController,
                  label: 'Partidos disputados',
                ),
                const SizedBox(height: 10),
                _StatField(
                  controller: amarillasController,
                  label: 'Tarjetas amarillas',
                ),
                const SizedBox(height: 10),
                _StatField(
                  controller: rojasController,
                  label: 'Tarjetas rojas',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _guardarCambios,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
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

class _StatField extends StatelessWidget {
  const _StatField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
    );
  }
}
