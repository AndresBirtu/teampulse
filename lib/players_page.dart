import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_player_page.dart';

class PlayersPage extends StatefulWidget {
  final String teamId;

  const PlayersPage({super.key, required this.teamId});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  String _sortBy = 'name'; // 'name', 'name-desc', 'position'
  String _filterPosition = ''; // '' = no filter
  bool _isCoach = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = (snapshot.data()?['role'] as String?)?.toLowerCase() ?? '';
      if (!mounted) return;
      setState(() {
        _isCoach = role == 'entrenador' || role == 'coach';
      });
    } catch (_) {
      // Ignorar, el botón simplemente no aparecerá
    }
  }

  Future<void> _markSanctionServed(String sanctionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('sanctions')
          .doc(sanctionId)
          .update({
        'status': 'served',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sanción marcada como cumplida')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la sanción: $e')),
      );
    }
  }

  void _confirmServeSanction(String sanctionId, String playerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar sanción cumplida'),
        content: Text('Confirmas que $playerName ya cumplió su sanción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _markSanctionServed(sanctionId);
            },
            child: const Text('Marcar cumplida'),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctionsPanel(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const SizedBox.shrink();

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
                  'Sanciones activas (${docs.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final playerName = data['playerName'] ?? 'Jugador';
              final opponent = data['opponent'] ?? 'Rival';
              final reason = data['reason'] ?? 'Tarjeta roja';
              final note = (data['notes'] ?? '').toString();
              final matchDate = (data['matchDate'] as Timestamp?)?.toDate();
              final dateText = matchDate != null
                  ? '${matchDate.day}/${matchDate.month}/${matchDate.year}'
                  : 'Fecha pendiente';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$reason vs $opponent · $dateText',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                    if (note.isNotEmpty)
                      Text(
                        'Nota: $note',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (_isCoach)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Marcar cumplida'),
                          onPressed: () => _confirmServeSanction(doc.id, playerName),
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

  void _showInjuryDialog(BuildContext context, String playerId, Map<String, dynamic> playerData, String playerName) {
    final isCurrentlyInjured = playerData['injured'] == true;
    final currentReturnDate = (playerData['injuryReturnDate'] as Timestamp?)?.toDate();
    
    DateTime? selectedDate = currentReturnDate;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isCurrentlyInjured ? 'Gestionar lesión' : 'Marcar como lesionado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jugador: $playerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (!isCurrentlyInjured) ...[
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
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                  ] else ...[
                    Container(
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
                              currentReturnDate != null
                                  ? 'Vuelta: ${currentReturnDate.day}/${currentReturnDate.month}/${currentReturnDate.year}'
                                  : 'Lesionado sin fecha de vuelta',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                if (isCurrentlyInjured)
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('teams')
                          .doc(widget.teamId)
                          .collection('players')
                          .doc(playerId)
                          .update({
                        'injured': false,
                        'injuryReturnDate': FieldValue.delete(),
                      });
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Jugador dado de alta ✅')),
                        );
                      }
                    },
                    child: const Text('Dar de alta', style: TextStyle(color: Colors.green)),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('teams')
                          .doc(widget.teamId)
                          .collection('players')
                          .doc(playerId)
                          .update({
                        'injured': true,
                        'injuryReturnDate': selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
                      });
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Jugador marcado como lesionado')),
                        );
                      }
                    },
                    child: const Text('Marcar lesionado', style: TextStyle(color: Colors.red)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playersStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('players')
        .snapshots();

    final sanctionsStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('sanctions')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jugadores del equipo"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: sanctionsStream,
        builder: (context, sanctionsSnapshot) {
          if (sanctionsSnapshot.hasError) {
            return Center(child: Text('Error cargando sanciones: ${sanctionsSnapshot.error}'));
          }

          final sanctionDocs = sanctionsSnapshot.data?.docs ?? [];
          final playerSanctions = <String, QueryDocumentSnapshot>{};
          for (final doc in sanctionDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final playerId = data['playerId'] as String?;
            if (playerId != null && playerId.isNotEmpty) {
              playerSanctions[playerId] = doc;
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: playersStream,
            builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var players = snapshot.data!.docs;
          
          // Filter out coaches from the list
          players = players.where((p) {
            final data = p.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            final isCoach = data['isCoach'] as bool? ?? false;
            return !isCoach && role?.toLowerCase() != 'entrenador' && role?.toLowerCase() != 'coach';
          }).toList();
          
          // Separate injured and sanctioned players
          final injuredPlayers = players.where((p) => (p.data() as Map<String, dynamic>)['injured'] == true).toList();
          final sanctionedPlayers = players.where((p) => playerSanctions.containsKey(p.id)).toList();
          final availablePlayers = players.where((p) {
            final data = p.data() as Map<String, dynamic>;
            final injured = data['injured'] == true;
            final sanctioned = playerSanctions.containsKey(p.id);
            return !injured && !sanctioned;
          }).toList();

          // Filtrar por posición si hay filtro activo
          if (_filterPosition.isNotEmpty) {
            players = players.where((p) => (p.data() as Map<String, dynamic>)['posicion'] == _filterPosition).toList();
          }

          // Ordenar según el criterio seleccionado
          players.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aName = aData['name'] ?? '';
            final aPos = aData['posicion'] ?? '';
            final bName = bData['name'] ?? '';
            final bPos = bData['posicion'] ?? '';

            switch (_sortBy) {
              case 'name':
                return aName.compareTo(bName); // A-Z
              case 'name-desc':
                return bName.compareTo(aName); // Z-A
              case 'position':
                return aPos.compareTo(bPos); // Por posición
              default:
                return 0;
            }
          });

          if (players.isEmpty) {
            return const Center(child: Text("No hay jugadores en el equipo"));
          }
          return Column(
            children: [
              _buildSanctionsPanel(sanctionDocs),
              // Controles de filtro y orden
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibles: ${availablePlayers.length} · Lesionados: ${injuredPlayers.length} · Sancionados: ${sanctionedPlayers.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _sortBy,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('A → Z')),
                          DropdownMenuItem(value: 'name-desc', child: Text('Z → A')),
                          DropdownMenuItem(value: 'position', child: Text('Por posición')),
                        ],
                        onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Filtrar por posición:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _filterPosition,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Todas las posiciones')),
                          ...['Portero', 'Cierre', 'Pivot', 'Ala']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                        ],
                        onChanged: (value) => setState(() => _filterPosition = value ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Injured players section
              if (injuredPlayers.isNotEmpty && _filterPosition.isEmpty)
                Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bajas por lesión (${injuredPlayers.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...injuredPlayers.map((player) {
                        final playerData = player.data() as Map<String, dynamic>;
                        final name = playerData['name'] ?? 'Jugador';
                        final injuryReturnDate = (playerData['injuryReturnDate'] as Timestamp?)?.toDate();
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person_off, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              if (injuryReturnDate != null)
                                Text(
                                  '${injuryReturnDate.day}/${injuryReturnDate.month}',
                                  style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              if (injuredPlayers.isNotEmpty && _filterPosition.isEmpty)
                const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final playerData = player.data() as Map<String, dynamic>;
                    final name = playerData['name'] ?? 'Jugador sin nombre';
                    final photoUrl = playerData['photoUrl'] ?? '';
                    final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();
                    final isInjured = playerData['injured'] == true;
                    final injuryReturnDate = (playerData['injuryReturnDate'] as Timestamp?)?.toDate();
                    final sanctionDoc = playerSanctions[player.id];
                    final isSanctioned = sanctionDoc != null;
                    final sanctionData = sanctionDoc?.data() as Map<String, dynamic>?;
                    final sanctionOpponent = sanctionData?['opponent'] ?? 'Rival';
                    final sanctionId = sanctionDoc?.id;
                    
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
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty
                                  ? Text(initials.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
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
                                name,
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
                              "Posición: ${playerData['posicion'] ?? '-'} · Partidos: ${playerData['partidos'] ?? 0}\nGoles: ${playerData['goles'] ?? 0} · Asist: ${playerData['asistencias'] ?? 0}",
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                            if (isInjured && injuryReturnDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Vuelta estimada: ${injuryReturnDate.day}/${injuryReturnDate.month}/${injuryReturnDate.year}',
                                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ] else if (isSanctioned) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.gavel, size: 12, color: Colors.deepOrange),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Pendiente por roja vs $sanctionOpponent. No alineable hasta que el entrenador marque la sanción como cumplida.',
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
                            if (_isCoach && isSanctioned && sanctionId != null) ...[
                              InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _confirmServeSanction(sanctionId, name),
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
                              onTap: () => _showInjuryDialog(context, player.id, playerData, name),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPlayerPage(
                                      teamId: widget.teamId,
                                      playerId: player.id,
                                      playerData: playerData,
                                    ),
                                  ),
                                );
                              },
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
                  },
                ),
              ),
            ],
          );
            },
          );
        },
      ),
    );
  }
}
