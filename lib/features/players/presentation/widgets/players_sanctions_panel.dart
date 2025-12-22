import 'package:flutter/material.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';

class PlayersSanctionsPanel extends StatelessWidget {
  const PlayersSanctionsPanel({
    super.key,
    required this.sanctions,
    required this.isCoach,
    required this.onServeSanction,
  });

  final List<Sanction> sanctions;
  final bool isCoach;
  final void Function(Sanction sanction) onServeSanction;

  @override
  Widget build(BuildContext context) {
    if (sanctions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: colorScheme.errorContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  'Sanciones activas (${sanctions.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sanctions.map((sanction) {
              final noteText = sanction.note.isNotEmpty ? 'Nota: ${sanction.note}' : '';
              final dateText = sanction.matchDate != null
                  ? '${sanction.matchDate!.day}/${sanction.matchDate!.month}/${sanction.matchDate!.year}'
                  : 'Fecha pendiente';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sanction.playerName,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${sanction.reason} vs ${sanction.opponent} · $dateText',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                    if (noteText.isNotEmpty)
                      Text(
                        noteText,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (isCoach)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Marcar cumplida'),
                          onPressed: () => onServeSanction(sanction),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
