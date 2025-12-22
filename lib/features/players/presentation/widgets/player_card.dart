import 'package:flutter/material.dart';
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
    required this.onEdit,
  });

  final Player player;
  final Sanction? sanction;
  final bool isCoach;
  final VoidCallback? onServeSanction;
  final VoidCallback onToggleInjury;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(player.name);
    final isInjured = player.injured;
    final isSanctioned = sanction != null;

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
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (isInjured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LESIONADO',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            else if (isSanctioned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.gavel, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'SANCIONADO',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
            ] else if (isSanctioned && sanction != null) ...[
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
