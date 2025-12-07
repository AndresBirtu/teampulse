import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

class LineupBuilderPage extends StatefulWidget {
  final String teamId;
  final String matchId;

  const LineupBuilderPage({super.key, required this.teamId, required this.matchId});

  @override
  State<LineupBuilderPage> createState() => _LineupBuilderPageState();
}

class _LineupBuilderPageState extends State<LineupBuilderPage> {
  static const double _tokenSize = 64;
  static const List<Offset> _defaultSlots = [
    Offset(0.5, 0.85),
    Offset(0.25, 0.65),
    Offset(0.75, 0.65),
    Offset(0.15, 0.4),
    Offset(0.5, 0.35),
    Offset(0.85, 0.4),
    Offset(0.32, 0.18),
    Offset(0.68, 0.18),
  ];

  final Map<String, PlayerMarker> _markers = {};
  bool _loadingLineup = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadExistingLineup();
  }

  Future<void> _loadExistingLineup() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId)
          .get();

      final data = doc.data();
      final lineup = data?['lineup'] as Map<String, dynamic>?;
      if (lineup == null) return;

      final List<dynamic> players = lineup['players'] as List<dynamic>? ?? [];
      final restored = <String, PlayerMarker>{};
      for (final entry in players) {
        if (entry is! Map<String, dynamic>) continue;
        final playerId = entry['playerId'] as String?;
        if (playerId == null) continue;
        final x = (entry['x'] as num?)?.toDouble() ?? 0.5;
        final y = (entry['y'] as num?)?.toDouble() ?? 0.5;
        restored[playerId] = PlayerMarker(
          playerId: playerId,
          name: entry['name'] as String? ?? 'Jugador',
          number: (entry['number'] as num?)?.toInt(),
          role: entry['role'] as String?,
          position: Offset(x.clamp(0.05, 0.95), y.clamp(0.05, 0.95)),
        );
      }

      if (mounted && restored.isNotEmpty) {
        setState(() {
          _markers
            ..clear()
            ..addAll(restored);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'No se pudo cargar la alineacion: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLineup = false);
      }
    }
  }

  Future<void> _saveLineup() async {
    if (_markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega jugadores antes de guardar')), 
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = _markers.values.map((marker) {
        return {
          'playerId': marker.playerId,
          'name': marker.name,
          'number': marker.number,
          'role': marker.role,
          'x': double.parse(marker.position.dx.toStringAsFixed(4)),
          'y': double.parse(marker.position.dy.toStringAsFixed(4)),
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .doc(widget.matchId)
          .set({
        'lineup': {
          'players': payload,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alineacion guardada ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _pruneMissingPlayers(Set<String> validIds) {
    final toRemove = _markers.keys.where((id) => !validIds.contains(id)).toList();
    if (toRemove.isEmpty) return;
    setState(() {
      for (final id in toRemove) {
        _markers.remove(id);
      }
    });
  }

  void _pruneSanctionedPlayers(Set<String> sanctionedIds) {
    if (sanctionedIds.isEmpty) return;
    final toRemove = _markers.keys.where(sanctionedIds.contains).toList();
    if (toRemove.isEmpty) return;
    setState(() {
      for (final id in toRemove) {
        _markers.remove(id);
      }
    });
  }

  void _addPlayerToField(PlayerInfo player) {
    if (player.isSanctioned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${player.name} tiene una sanción activa y no puede alinearse.')),
      );
      return;
    }
    if (_markers.containsKey(player.id)) return;
    final slotIndex = math.min(_markers.length, _defaultSlots.length - 1);
    setState(() {
      _markers[player.id] = PlayerMarker(
        playerId: player.id,
        name: player.name,
        number: player.number,
        role: player.position,
        position: _defaultSlots[slotIndex],
      );
    });
  }

  void _removePlayer(String playerId) {
    if (!_markers.containsKey(playerId)) return;
    setState(() => _markers.remove(playerId));
  }

  void _clearLineup() {
    if (_markers.isEmpty) return;
    setState(() => _markers.clear());
  }

  void _onMarkerDragged(String playerId, Offset delta, Size fieldSize) {
    final marker = _markers[playerId];
    if (marker == null) return;
    final actual = Offset(
      marker.position.dx * fieldSize.width,
      marker.position.dy * fieldSize.height,
    );
    final updated = actual + delta;
    final half = _tokenSize / 2;
    final clamped = Offset(
      updated.dx.clamp(half, fieldSize.width - half),
      updated.dy.clamp(half, fieldSize.height - half),
    );
    setState(() {
      _markers[playerId] = marker.copyWith(
        position: Offset(
          clamped.dx / fieldSize.width,
          clamped.dy / fieldSize.height,
        ),
      );
    });
  }

  void _autoDistribute(List<PlayerInfo> players) {
    if (players.isEmpty) return;
    final slots = _defaultSlots.length;
    setState(() {
      _markers.clear();
      for (var i = 0; i < players.length && i < slots; i++) {
        final player = players[i];
        _markers[player.id] = PlayerMarker(
          playerId: player.id,
          name: player.name,
          number: player.number,
          role: player.position,
          position: _defaultSlots[i],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sanctionsStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('sanctions')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final playersStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('players')
        .orderBy('name')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alineacion interactiva'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _saving ? null : _saveLineup,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: sanctionsStream,
        builder: (context, sanctionsSnapshot) {
          if (sanctionsSnapshot.hasError) {
            return Center(child: Text('Error cargando sanciones: ${sanctionsSnapshot.error}'));
          }

          final sanctionedIds = <String>{};
          if (sanctionsSnapshot.hasData) {
            for (final doc in sanctionsSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final pid = data['playerId'] as String?;
              if (pid != null && pid.isNotEmpty) {
                sanctionedIds.add(pid);
              }
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: playersStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final players = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final role = (data['role'] as String?)?.toLowerCase();
                final isCoach = (data['isCoach'] as bool?) ?? false;
                if (role == 'entrenador' || role == 'coach' || isCoach) {
                  return null;
                }
                final isSanctioned = sanctionedIds.contains(doc.id);
                return PlayerInfo(
                  id: doc.id,
                  name: data['name'] as String? ?? 'Jugador',
                  number: (data['dorsal'] as num?)?.toInt(),
                  position: data['posicion'] as String?,
                  isSanctioned: isSanctioned,
                );
              }).whereType<PlayerInfo>().toList();

              final benchPlayers = players.where((p) => !_markers.containsKey(p.id)).toList();
              final eligiblePlayers = players.where((p) => !p.isSanctioned).toList();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _pruneMissingPlayers(players.map((p) => p.id).toSet());
                _pruneSanctionedPlayers(sanctionedIds);
              });

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loadingLineup
                        ? const LinearProgressIndicator(minHeight: 2)
                        : const SizedBox(height: 2),
                    if (_loadError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_loadError!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInstructionCard(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: _buildPitch()),
                          const SizedBox(height: 16),
                          _buildBench(benchPlayers, eligiblePlayers),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPitch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PitchPainter(lineColor: Colors.white.withOpacity(0.85)),
                ),
              ),
              ..._markers.values.map((marker) {
                final actual = Offset(
                  marker.position.dx * fieldSize.width,
                  marker.position.dy * fieldSize.height,
                );
                return Positioned(
                  left: actual.dx - _tokenSize / 2,
                  top: actual.dy - _tokenSize / 2,
                  child: GestureDetector(
                    onPanUpdate: (details) => _onMarkerDragged(marker.playerId, details.delta, fieldSize),
                    onLongPress: () => _removePlayer(marker.playerId),
                    child: _PlayerToken(marker: marker),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBench(List<PlayerInfo> benchPlayers, List<PlayerInfo> eligiblePlayers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Banca (${benchPlayers.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              tooltip: 'Vaciar cancha',
              onPressed: _markers.isEmpty ? null : _clearLineup,
              icon: const Icon(Icons.clear_all),
            ),
            IconButton(
              tooltip: 'Auto 2-2-1 con primeros jugadores',
              onPressed: eligiblePlayers.isEmpty ? null : () => _autoDistribute(eligiblePlayers),
              icon: const Icon(Icons.auto_fix_high),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (benchPlayers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text('Todos los jugadores están en la cancha. Mantén presionado un marcador para enviarlo de vuelta a la banca.'),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: benchPlayers.map((player) {
                  return InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        player.initials,
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    label: Text(
                      player.isSanctioned ? '${player.displayName} (Sancionado)' : player.displayName,
                    ),
                    tooltip: player.isSanctioned ? 'Tiene sanción activa' : null,
                    onPressed: player.isSanctioned ? null : () => _addPlayerToField(player),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.touch_app, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Toca un jugador para llevarlo al campo, arrastra las bolitas para colocarlas y mantén presionada una para devolverla a la banca.',
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerInfo {
  final String id;
  final String name;
  final int? number;
  final String? position;
  final bool isSanctioned;

  const PlayerInfo({
    required this.id,
    required this.name,
    this.number,
    this.position,
    this.isSanctioned = false,
  });

  String get displayName => number == null ? name : '#${number!} $name';
  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class PlayerMarker {
  final String playerId;
  final String name;
  final int? number;
  final String? role;
  final Offset position;

  const PlayerMarker({
    required this.playerId,
    required this.name,
    this.number,
    this.role,
    required this.position,
  });

  PlayerMarker copyWith({Offset? position}) {
    return PlayerMarker(
      playerId: playerId,
      name: name,
      number: number,
      role: role,
      position: position ?? this.position,
    );
  }
}

class _PlayerToken extends StatelessWidget {
  final PlayerMarker marker;

  const _PlayerToken({required this.marker});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Mantén presionado para enviar a ${marker.name} a la banca',
          child: Container(
            width: _LineupBuilderPageState._tokenSize,
            height: _LineupBuilderPageState._tokenSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
            ),
            child: Center(
              child: Text(
                marker.number?.toString() ?? marker.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            marker.name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  final Color lineColor;

  _PitchPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(28),
    );
    canvas.drawRRect(fieldRect, paint);

    // Media cancha y circulo central
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawCircle(Offset(size.width / 2, midY), size.width * 0.18, paint);

    // Areas
    final areaWidth = size.width * 0.6;
    final areaHeight = size.height * 0.18;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, areaHeight / 2),
        width: areaWidth,
        height: areaHeight,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - areaHeight / 2),
        width: areaWidth,
        height: areaHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) => false;
}
