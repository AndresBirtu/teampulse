import 'package:flutter/material.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/presentation/viewmodels/players_view_model.dart';

Future<void> showPlayerInjuryDialog({
  required BuildContext context,
  required Player player,
  required PlayersViewModel controller,
}) async {
  final rootContext = context;
  DateTime? selectedDate = player.injuryReturnDate ?? DateTime.now().add(const Duration(days: 7));

  await showDialog<void>(
    context: rootContext,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(player.injured ? 'Gestionar lesión' : 'Marcar como lesionado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jugador: ${player.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (!player.injured) ...[
                const Text('Fecha estimada de vuelta:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Seleccionar fecha',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ] else ...[
                _InjuryInfoCard(player: player),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            if (player.injured)
              TextButton(
                onPressed: () async {
                  try {
                    await controller.clearPlayerInjury(player.id);
                    if (rootContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Jugador dado de alta ✅')),
                      );
                    }
                  } catch (e) {
                    if (rootContext.mounted) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('No se pudo actualizar: $e')),
                      );
                    }
                  }
                },
                child: const Text('Dar de alta', style: TextStyle(color: Colors.green)),
              )
            else
              TextButton(
                onPressed: () async {
                  try {
                    await controller.markPlayerInjury(
                      player.id,
                      estimatedReturn: selectedDate,
                    );
                    if (rootContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Jugador marcado como lesionado')),
                      );
                    }
                  } catch (e) {
                    if (rootContext.mounted) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('No se pudo actualizar: $e')),
                      );
                    }
                  }
                },
                child: const Text('Marcar lesionado', style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    ),
  );
}

class _InjuryInfoCard extends StatelessWidget {
  const _InjuryInfoCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.injuryReturnDate != null
                  ? 'Vuelta: ${player.injuryReturnDate!.day}/${player.injuryReturnDate!.month}/${player.injuryReturnDate!.year}'
                  : 'Lesionado sin fecha de vuelta',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
