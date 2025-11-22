import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchAvailabilityPage extends StatefulWidget {
  final String teamId;
  final String matchId;
  final bool isCoach;

  const MatchAvailabilityPage({
    required this.teamId,
    required this.matchId,
    required this.isCoach,
    super.key,
  });

  @override
  State<MatchAvailabilityPage> createState() => _MatchAvailabilityPageState();
}

class _MatchAvailabilityPageState extends State<MatchAvailabilityPage> {
  String? _currentUserId;
  Map<String, dynamic>? _matchData;
  List<String> _convocados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      final matchDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId)
          .get();
      
      if (matchDoc.exists) {
        setState(() {
          _matchData = matchDoc.data();
          _convocados = List<String>.from(_matchData?['convocados'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando partido: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvailability(String status) async {
    if (_currentUserId == null) return;

    try {
      // Obtener nombre del jugador
      final playerDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .doc(_currentUserId)
          .get();
      
      final playerName = playerDoc.data()?['name'] ?? 'Jugador';

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId)
          .collection('availability')
          .doc(_currentUserId)
          .set({
        'playerId': _currentUserId,
        'playerName': playerName,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilidad actualizada ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleConvocado(String playerId, bool isConvocado) async {
    try {
      List<String> updatedConvocados = List<String>.from(_convocados);
      if (isConvocado && !updatedConvocados.contains(playerId)) {
        updatedConvocados.add(playerId);
      } else if (!isConvocado && updatedConvocados.contains(playerId)) {
        updatedConvocados.remove(playerId);
      }

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId)
          .update({'convocados': updatedConvocados});

      // También actualizar el campo 'convocado' en stats si existe
      try {
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('matches')
            .doc(widget.matchId)
            .collection('stats')
            .doc(playerId)
            .set({'convocado': isConvocado}, SetOptions(merge: true));
      } catch (_) {
        // Stats doc might not exist yet
      }

      setState(() => _convocados = updatedConvocados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isConvocado ? 'Jugador convocado' : 'Jugador desconvocado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final teamA = _matchData?['teamA'] ?? 'Equipo A';
    final teamB = _matchData?['teamB'] ?? 'Equipo B';
    final date = (_matchData?['date'] as Timestamp?)?.toDate();
    final formattedDate = date != null
        ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
        : "Sin fecha";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCoach ? 'Convocatorias' : 'Disponibilidad'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del partido
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$teamA vs $teamB',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(formattedDate, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            // Vista para jugadores: marcar disponibilidad
            if (!widget.isCoach) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Vas a venir al partido?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('teams')
                          .doc(widget.teamId)
                          .collection('matches')
                          .doc(widget.matchId)
                          .collection('availability')
                          .doc(_currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final myAvailability = snapshot.data?.data() as Map<String, dynamic>?;
                        final myStatus = myAvailability?['status'] as String?;

                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Sí'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myStatus == 'yes' ? Colors.green : Colors.grey[300],
                                  foregroundColor: myStatus == 'yes' ? Colors.white : Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => _updateAvailability('yes'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.help_outline),
                                label: const Text('Dudoso'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myStatus == 'maybe' ? Colors.orange : Colors.grey[300],
                                  foregroundColor: myStatus == 'maybe' ? Colors.white : Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => _updateAvailability('maybe'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.cancel),
                                label: const Text('No'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myStatus == 'no' ? Colors.red : Colors.grey[300],
                                  foregroundColor: myStatus == 'no' ? Colors.white : Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => _updateAvailability('no'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Estado de convocatoria:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildPlayerConvocationStatus(),
                  ],
                ),
              ),
            ],

            // Vista para entrenador: gestionar convocatorias
            if (widget.isCoach) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestionar convocatorias',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona los jugadores convocados para este partido',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildPlayersListForCoach(),
                  ],
                ),
              ),
            ],

            // Resumen de disponibilidad (visible para todos)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Disponibilidad de jugadores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildAvailabilitySummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerConvocationStatus() {
    final isConvocado = _convocados.contains(_currentUserId);

    return Card(
      color: isConvocado ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isConvocado ? Icons.check_circle : Icons.pending,
              color: isConvocado ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isConvocado
                    ? '¡Estás convocado para este partido!'
                    : 'Aún no estás en la convocatoria',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isConvocado ? Colors.green[900] : Colors.orange[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersListForCoach() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .snapshots(),
      builder: (context, playersSnapshot) {
        if (!playersSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('matches')
              .doc(widget.matchId)
              .collection('availability')
              .snapshots(),
          builder: (context, availSnapshot) {
            final availabilityMap = <String, String>{};
            if (availSnapshot.hasData) {
              for (final doc in availSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                availabilityMap[doc.id] = data['status'] as String? ?? 'unknown';
              }
            }

            final players = playersSnapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final playerDoc = players[index];
                final playerData = playerDoc.data() as Map<String, dynamic>;
                final playerId = playerDoc.id;
                final playerName = playerData['name'] ?? 'Jugador';
                final role = playerData['role'] as String?;
                final isCoachFlag = playerData['isCoach'] as bool? ?? false;
                final isCoach = isCoachFlag || role?.toLowerCase() == 'coach' || role?.toLowerCase() == 'entrenador';

                // No mostrar entrenadores en la lista
                if (isCoach) return const SizedBox.shrink();

                final isConvocado = _convocados.contains(playerId);
                final availability = availabilityMap[playerId];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    value: isConvocado,
                    onChanged: (value) => _toggleConvocado(playerId, value ?? false),
                    title: Text(playerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: _buildAvailabilityChip(availability),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAvailabilitySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId)
          .collection('availability')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final availabilities = snapshot.data!.docs;

        if (availabilities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ningún jugador ha indicado su disponibilidad aún',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('players')
              .snapshots(),
          builder: (context, playersSnapshot) {
            if (!playersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Crear mapa de jugadores para verificar roles
            final playersMap = <String, Map<String, dynamic>>{};
            for (final playerDoc in playersSnapshot.data!.docs) {
              playersMap[playerDoc.id] = playerDoc.data() as Map<String, dynamic>;
            }

            // Filtrar disponibilidades para excluir entrenadores
            final filteredAvailabilities = availabilities.where((availDoc) {
              final playerId = availDoc.id;
              final playerData = playersMap[playerId];
              if (playerData == null) return true; // Mostrar si no encontramos data del jugador
              
              final role = playerData['role'] as String?;
              final isCoachFlag = playerData['isCoach'] as bool? ?? false;
              final isCoach = isCoachFlag || 
                              role?.toLowerCase() == 'coach' || 
                              role?.toLowerCase() == 'entrenador';
              return !isCoach; // Excluir entrenadores
            }).toList();

            if (filteredAvailabilities.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ningún jugador ha indicado su disponibilidad aún',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredAvailabilities.length,
              itemBuilder: (context, index) {
                final avail = filteredAvailabilities[index].data() as Map<String, dynamic>;
                final playerName = avail['playerName'] ?? 'Jugador';
                final status = avail['status'] as String?;
                final playerId = filteredAvailabilities[index].id;
                final isConvocado = _convocados.contains(playerId);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: _getStatusIcon(status),
                    title: Text(playerName),
                    subtitle: _buildAvailabilityChip(status),
                    trailing: isConvocado
                        ? const Chip(
                            label: Text('Convocado', style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAvailabilityChip(String? status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'yes':
        color = Colors.green;
        text = 'Confirmado';
        icon = Icons.check_circle;
        break;
      case 'maybe':
        color = Colors.orange;
        text = 'Dudoso';
        icon = Icons.help_outline;
        break;
      case 'no':
        color = Colors.red;
        text = 'No asiste';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Sin respuesta';
        icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  Icon _getStatusIcon(String? status) {
    switch (status) {
      case 'yes':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'maybe':
        return const Icon(Icons.help_outline, color: Colors.orange);
      case 'no':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}
