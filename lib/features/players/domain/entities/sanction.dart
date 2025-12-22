class Sanction {
  const Sanction({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.opponent,
    required this.reason,
    required this.note,
    required this.matchDate,
    required this.status,
  });

  final String id;
  final String playerId;
  final String playerName;
  final String opponent;
  final String reason;
  final String note;
  final DateTime? matchDate;
  final String status;

  bool get isPending => status.toLowerCase() == 'pending';
}
