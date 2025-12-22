import 'package:flutter/material.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';

class PlayersInjuriesPanel extends StatelessWidget {
  const PlayersInjuriesPanel({super.key, required this.injuredPlayers});

  final List<Player> injuredPlayers;

  @override
  Widget build(BuildContext context) {
    if (injuredPlayers.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.red.shade50,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bajas por lesión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
              ),
              Text(' (${injuredPlayers.length})', style: const TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          ...injuredPlayers.map((player) {
            final injuryDate = player.injuryReturnDate;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_off, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (injuryDate != null)
                    Text(
                      '${injuryDate.day}/${injuryDate.month}',
                      style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
