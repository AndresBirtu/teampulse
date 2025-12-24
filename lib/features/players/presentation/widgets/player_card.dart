import 'package:flutter/material.dart';
import 'package:teampulse/features/players/constants/injury_areas.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    required this.sanction,
    required this.isCoach,
    required this.onServeSanction,
    required this.onToggleInjury,
    required this.onCaptainToggle,
    required this.onEdit,
  });

  final Player player;
  final Sanction? sanction;
  final bool isCoach;
  final VoidCallback? onServeSanction;
  final VoidCallback onToggleInjury;
  final ValueChanged<bool> onCaptainToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(player.name);
    final isInjured = player.injured;
    final isSanctioned = sanction != null;

    final injuryAreaLabel = player.injuryArea == null ? null : describeInjuryArea(player.injuryArea);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: isSanctioned
          ? Colors.orange.shade50
          : isInjured
              ? Colors.red.shade50
              : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
              backgroundImage: player.photoUrl.isNotEmpty ? NetworkImage(player.photoUrl) : null,
              child: player.photoUrl.isEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isInjured)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (player.isCaptain)
                  _StatusPill(
                    color: Colors.amber.shade600,
                    textColor: Colors.black,
                    icon: Icons.star,
                    label: 'CAPITÁN',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (isInjured)
                  _StatusPill(
                    color: Colors.red,
                    textColor: Colors.white,
                    icon: Icons.healing,
                    label: 'LESIONADO',
                  )
                else if (isSanctioned)
                  _StatusPill(
                    color: Colors.deepOrange,
                    textColor: Colors.white,
                    icon: Icons.gavel,
                    label: 'SANCIONADO',
                  ),
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Posición: ${player.position.isEmpty ? '-' : player.position} · Partidos: ${player.matches}\nGoles: ${player.goals} · Asist: ${player.assists}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            if (isInjured && player.injuryReturnDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Vuelta estimada: ${player.injuryReturnDate!.day}/${player.injuryReturnDate!.month}/${player.injuryReturnDate!.year}',
                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (isInjured && injuryAreaLabel != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Zona afectada: $injuryAreaLabel',
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (!isInjured && isSanctioned && sanction != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.gavel, size: 12, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pendiente por ${sanction!.reason} vs ${sanction!.opponent}.',
                      style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (isCoach) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    player.isCaptain ? Icons.star : Icons.star_border,
                    size: 16,
                    color: player.isCaptain ? Colors.amber.shade700 : Theme.of(context).primaryColor,
                  ),
                  label: Text(
                    player.isCaptain ? 'Quitar capitanía' : 'Asignar capitanía',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  onPressed: () => onCaptainToggle(!player.isCaptain),
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCoach && isSanctioned && onServeSanction != null) ...[
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onServeSanction,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green.withOpacity(0.16),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                ),
              ),
              const SizedBox(width: 8),
            ],
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onToggleInjury,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isInjured ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                child: Icon(
                  isInjured ? Icons.healing : Icons.medical_services_outlined,
                  color: isInjured ? Colors.red : Colors.orange,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onEdit,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                child: Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
