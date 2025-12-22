import 'package:flutter/material.dart';
import 'package:teampulse/features/players/presentation/state/players_state.dart';
import 'package:teampulse/features/players/presentation/viewmodels/players_view_model.dart';

class PlayersFilterPanel extends StatelessWidget {
  const PlayersFilterPanel({
    super.key,
    required this.state,
    required this.controller,
  });

  final PlayersState state;
  final PlayersViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disponibles: ${state.availablePlayers.length} · Lesionados: ${state.injuredPlayers.length} · Sancionados: ${state.sanctionedPlayers.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          _BorderedDropdown(
            child: DropdownButton<PlayersSort>(
              isExpanded: true,
              underline: const SizedBox(),
              value: state.sort,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: const [
                DropdownMenuItem(value: PlayersSort.nameAsc, child: Text('A → Z')),
                DropdownMenuItem(value: PlayersSort.nameDesc, child: Text('Z → A')),
                DropdownMenuItem(value: PlayersSort.position, child: Text('Por posición')),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.changeSort(value);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('Filtrar por posición:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          _BorderedDropdown(
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: state.filterPosition,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: const [
                DropdownMenuItem(value: '', child: Text('Todas las posiciones')),
                DropdownMenuItem(value: 'Portero', child: Text('Portero')),
                DropdownMenuItem(value: 'Cierre', child: Text('Cierre')),
                DropdownMenuItem(value: 'Pivot', child: Text('Pivot')),
                DropdownMenuItem(value: 'Ala', child: Text('Ala')),
              ],
              onChanged: (value) => controller.changeFilter(value ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _BorderedDropdown extends StatelessWidget {
  const _BorderedDropdown({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
