import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teampulse/features/matches/domain/entities/match_availability.dart';
import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/player_match_stat.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';
import 'package:teampulse/features/matches/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<TeamMatch>> watchTeamMatches(String teamId) {
    return _matchCollection(teamId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapToEntity(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<TeamMatch?> watchMatch(String teamId, String matchId) {
    return _matchDoc(teamId, matchId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return _mapToEntity(snapshot.id, data);
    });
  }

  @override
  Stream<List<MatchAvailability>> watchAvailability(String teamId, String matchId) {
    return _availabilityCollection(teamId, matchId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapAvailability(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<MatchPlayer>> watchMatchPlayers(String teamId) {
    return _playerCollection(teamId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final role = (data['role'] as String?)?.toLowerCase() ?? '';
        final isCoachFlag = data['isCoach'] as bool? ?? false;
        final isCoach = isCoachFlag || role == 'coach' || role == 'entrenador';
        return MatchPlayer(
          id: doc.id,
          name: (data['name'] as String?)?.trim() ?? 'Jugador',
          isCoach: isCoach,
        );
      }).toList();
    });
  }

  @override
  Stream<List<PlayerMatchStat>> watchMatchStats(String teamId, String matchId) {
    return _statsCollection(teamId, matchId)
        .orderBy('playerName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapPlayerStat(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<bool> isCoach(String userId) async {
    if (userId.isEmpty) return false;
    final doc = await _firestore.collection('users').doc(userId).get();
    final role = (doc.data()?['role'] as String?)?.toLowerCase() ?? '';
    return role == 'entrenador' || role == 'coach';
  }

  @override
  Future<String?> loadTeamName(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    final rawName = doc.data()?['name'] as String?;
    if (rawName == null) return null;
    final trimmed = rawName.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<String?> loadTeamCoachId(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    final rawCoachId = doc.data()?['coachId'] as String?;
    if (rawCoachId == null) return null;
    final trimmed = rawCoachId.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<MatchCreationResult> createMatch({
    required String teamId,
    required String teamA,
    required String teamB,
    required DateTime date,
    required bool played,
    int? goalsTeamA,
    int? goalsTeamB,
  }) async {
    final payload = <String, dynamic>{
      'teamA': teamA.trim(),
      'teamB': teamB.trim(),
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
      'played': played,
      'convocados': <String>[],
    };

    if (played) {
      payload['golesTeamA'] = goalsTeamA ?? 0;
      payload['golesTeamB'] = goalsTeamB ?? 0;
    }

    final matchRef = await _matchCollection(teamId).add(payload);
    final statsGenerated = await _generateStatsSheet(teamId: teamId, matchRef: matchRef);

    return MatchCreationResult(matchId: matchRef.id, statsGenerated: statsGenerated);
  }

  @override
  Future<void> updateMatchNote({
    required String teamId,
    required String matchId,
    required String note,
    required String userId,
  }) async {
    final resolvedUser = userId.isEmpty ? _auth.currentUser?.uid : userId;
    await _matchDoc(teamId, matchId).update({
      'note': note,
      'noteUpdatedAt': FieldValue.serverTimestamp(),
      if (resolvedUser != null) 'noteUpdatedBy': resolvedUser,
    });
  }

  @override
  Future<void> deleteMatch({
    required String teamId,
    required TeamMatch match,
  }) async {
    final matchRef = _matchDoc(teamId, match.id);
    if (match.aggregated) {
      await _revertStatsFromPlayers(teamId, match.id);
    }

    final statsSnap = await _statsCollection(teamId, match.id).get();
    if (statsSnap.docs.isNotEmpty) {
      final batchDelete = _firestore.batch();
      for (final stat in statsSnap.docs) {
        batchDelete.delete(stat.reference);
      }
      await batchDelete.commit();
    }

    await matchRef.delete();
  }

  @override
  Future<void> updateMatchResult({
    required String teamId,
    required TeamMatch match,
    required bool played,
    int? goalsTeamA,
    int? goalsTeamB,
  }) async {
    final matchRef = _matchDoc(teamId, match.id);
    final doc = await matchRef.get();
    final aggregated = (doc.data()?['aggregated'] ?? false) as bool;

    final payload = <String, dynamic>{'played': played};
    if (played) {
      payload['golesTeamA'] = goalsTeamA ?? 0;
      payload['golesTeamB'] = goalsTeamB ?? 0;
    }

    await matchRef.update(payload);

    if (played && !aggregated) {
      await _applyStatsToPlayers(teamId, match.id);
    }
  }

  @override
  Future<void> updateAvailability({
    required String teamId,
    required String matchId,
    required String playerId,
    required MatchAvailabilityStatus status,
    String? reason,
  }) async {
    final playerDoc = await _playerDoc(teamId, playerId).get();
    final playerName = (playerDoc.data()?['name'] as String?) ?? 'Jugador';

    await _availabilityCollection(teamId, matchId)
        .doc(playerId)
        .set({
      'playerId': playerId,
      'playerName': playerName,
      'status': matchAvailabilityStatusToString(status),
      'reason': (reason ?? '').trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleConvocado({
    required String teamId,
    required String matchId,
    required String playerId,
    required bool isConvocado,
  }) async {
    final matchRef = _matchDoc(teamId, matchId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;
      final List<dynamic> rawConvocados = (snapshot.data()?['convocados'] as List<dynamic>?) ?? <dynamic>[];
      final convocados = rawConvocados.whereType<String>().toList();

      if (isConvocado && !convocados.contains(playerId)) {
        convocados.add(playerId);
      } else if (!isConvocado && convocados.contains(playerId)) {
        convocados.remove(playerId);
      }

      transaction.update(matchRef, {'convocados': convocados});
    });

    await matchRef
        .collection('stats')
        .doc(playerId)
        .set({'convocado': isConvocado}, SetOptions(merge: true));
  }

  @override
  Future<void> updateCoachMessage({
    required String teamId,
    required String matchId,
    required String? message,
  }) async {
    final data = <String, dynamic>{
      'coachMessageUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (message == null || message.trim().isEmpty) {
      data['coachMessage'] = FieldValue.delete();
    } else {
      data['coachMessage'] = message.trim();
    }

    await _matchDoc(teamId, matchId).update(data);
  }

  @override
  Future<void> updatePlayerStats({
    required String teamId,
    required String matchId,
    required String playerId,
    required Map<String, dynamic> updates,
  }) {
    if (updates.isEmpty) return Future.value();
    return _statDoc(teamId, matchId, playerId).set(updates, SetOptions(merge: true));
  }

  @override
  Future<void> ensureStatsAppliedIfNeeded({
    required String teamId,
    required String matchId,
  }) async {
    final matchSnapshot = await _matchDoc(teamId, matchId).get();
    final data = matchSnapshot.data();
    if (data == null) return;
    final played = data['played'] == true;
    final aggregated = data['aggregated'] == true;
    if (!played || aggregated) return;
    await _applyStatsToPlayers(teamId, matchId);
  }

  @override
  Future<void> applyStatsToPlayers({
    required String teamId,
    required String matchId,
  }) {
    return _applyStatsToPlayers(teamId, matchId);
  }

  @override
  Future<void> revertStatsFromPlayers({
    required String teamId,
    required String matchId,
  }) {
    return _revertStatsFromPlayers(teamId, matchId);
  }

  @override
  Future<void> registerRedCardSanction({
    required String teamId,
    required String matchId,
    required String playerId,
    required String playerName,
  }) async {
    final sanctionsRef = _sanctionsCollection(teamId);
    final existing = await sanctionsRef
        .where('playerId', isEqualTo: playerId)
        .where('matchId', isEqualTo: matchId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final matchSnapshot = await _matchDoc(teamId, matchId).get();
    final matchData = matchSnapshot.data() ?? <String, dynamic>{};

    await sanctionsRef.add({
      'playerId': playerId,
      'playerName': playerName,
      'matchId': matchId,
      'matchDate': matchData['date'],
      'opponent': matchData['teamB'] ?? matchData['rival'] ?? matchData['opponent'] ?? '',
      'status': 'pending',
      'reason': 'Tarjeta roja',
      'notes': matchData['note'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeRedCardSanction({
    required String teamId,
    required String matchId,
    required String playerId,
  }) async {
    final sanctionsRef = _sanctionsCollection(teamId);
    final existing = await sanctionsRef
        .where('playerId', isEqualTo: playerId)
        .where('matchId', isEqualTo: matchId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isEmpty) return;
    await existing.docs.first.reference.delete();
  }

  CollectionReference<Map<String, dynamic>> _matchCollection(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('matches');
  }

  DocumentReference<Map<String, dynamic>> _matchDoc(String teamId, String matchId) {
    return _matchCollection(teamId).doc(matchId);
  }

  DocumentReference<Map<String, dynamic>> _playerDoc(String teamId, String playerId) {
    return _playerCollection(teamId).doc(playerId);
  }

  CollectionReference<Map<String, dynamic>> _playerCollection(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('players');
  }

  CollectionReference<Map<String, dynamic>> _availabilityCollection(String teamId, String matchId) {
    return _matchDoc(teamId, matchId).collection('availability');
  }

  CollectionReference<Map<String, dynamic>> _statsCollection(String teamId, String matchId) {
    return _matchDoc(teamId, matchId).collection('stats');
  }

  DocumentReference<Map<String, dynamic>> _statDoc(String teamId, String matchId, String playerId) {
    return _statsCollection(teamId, matchId).doc(playerId);
  }

  CollectionReference<Map<String, dynamic>> _sanctionsCollection(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('sanctions');
  }

  TeamMatch _mapToEntity(String id, Map<String, dynamic> data) {
    final rawConvocados = data['convocados'];
    final convocados = rawConvocados is List
        ? rawConvocados.whereType<String>().toList()
        : const <String>[];

    return TeamMatch(
      id: id,
      teamA: (data['teamA'] as String?) ?? 'Equipo A',
      teamB: (data['teamB'] as String?) ?? 'Equipo B',
      date: _parseDate(data['date']),
      played: data['played'] == true,
      goalsTeamA: _asInt(data['golesTeamA']),
      goalsTeamB: _asInt(data['golesTeamB']),
      aggregated: data['aggregated'] == true,
      note: (data['note'] as String?) ?? '',
      convocados: convocados,
      coachMessage: (data['coachMessage'] as String?)?.trim(),
      coachMessageUpdatedAt: _parseDate(data['coachMessageUpdatedAt']),
    );
  }

  MatchAvailability _mapAvailability(String id, Map<String, dynamic> data) {
    return MatchAvailability(
      playerId: id,
      playerName: (data['playerName'] as String?) ?? 'Jugador',
      status: matchAvailabilityStatusFromString(data['status'] as String?),
      reason: (data['reason'] as String?) ?? '',
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  PlayerMatchStat _mapPlayerStat(String id, Map<String, dynamic> data) {
    final rawName = (data['playerName'] as String?)?.trim();
    return PlayerMatchStat(
      playerId: id,
      playerName: (rawName == null || rawName.isEmpty) ? 'Jugador' : rawName,
      convocado: _asBool(data['convocado'], defaultValue: true),
      titular: _asBool(data['titular']),
      isCoach: _asBool(data['isCoach']),
      goals: _asInt(data['goles']),
      assists: _asInt(data['asistencias']),
      yellowCards: _asInt(data['amarillas'] ?? data['tarjetas_amarillas']),
      redCards: _asInt(data['rojas'] ?? data['tarjetas_rojas']),
      minutes: _asInt(data['minutos']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return defaultValue;
  }

  Future<void> _applyStatsToPlayers(String teamId, String matchId) async {
    final matchRef = _matchDoc(teamId, matchId);
    final statsSnap = await _statsCollection(teamId, matchId).get();
    if (statsSnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final stat in statsSnap.docs) {
      final data = stat.data();
      final playedMinutes = _asInt(data['minutos']);
      final convocado = data['convocado'];
      if (convocado is bool && !convocado) continue;
      final playerRef = _playerDoc(teamId, stat.id);
      batch.set(playerRef, {
        'goles': FieldValue.increment(_asInt(data['goles'])),
        'asistencias': FieldValue.increment(_asInt(data['asistencias'])),
        'minutos': FieldValue.increment(playedMinutes),
        'partidos': FieldValue.increment(playedMinutes > 0 ? 1 : 0),
        'tarjetas_amarillas': FieldValue.increment(_asInt(data['amarillas'] ?? data['tarjetas_amarillas'])),
        'tarjetas_rojas': FieldValue.increment(_asInt(data['rojas'] ?? data['tarjetas_rojas'])),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    await matchRef.update({'aggregated': true});
  }

  Future<void> _revertStatsFromPlayers(String teamId, String matchId) async {
    final matchRef = _matchDoc(teamId, matchId);
    final matchSnap = await matchRef.get();
    final aggregated = (matchSnap.data()?['aggregated'] ?? false) as bool;
    if (!aggregated) return;

    final statsSnap = await _statsCollection(teamId, matchId).get();
    if (statsSnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final stat in statsSnap.docs) {
      final data = stat.data();
      final convocado = data['convocado'];
      if (convocado is bool && !convocado) continue;
      final playerRef = _playerDoc(teamId, stat.id);
      final playedMinutes = _asInt(data['minutos']);
      batch.set(playerRef, {
        'goles': FieldValue.increment(-_asInt(data['goles'])),
        'asistencias': FieldValue.increment(-_asInt(data['asistencias'])),
        'minutos': FieldValue.increment(-playedMinutes),
        'partidos': FieldValue.increment(playedMinutes > 0 ? -1 : 0),
        'tarjetas_amarillas': FieldValue.increment(-_asInt(data['amarillas'] ?? data['tarjetas_amarillas'])),
        'tarjetas_rojas': FieldValue.increment(-_asInt(data['rojas'] ?? data['tarjetas_rojas'])),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    await matchRef.update({'aggregated': false});
  }

  Future<bool> _generateStatsSheet({
    required String teamId,
    required DocumentReference<Map<String, dynamic>> matchRef,
  }) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      final teamCoachId = teamDoc.data()?['coachId'] as String?;

      final playersSnap = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('players')
          .get();

      if (playersSnap.docs.isEmpty) {
        return true;
      }

      final batch = _firestore.batch();
      for (final player in playersSnap.docs) {
        final playerData = player.data();
        final role = playerData['role'] as String?;
        final isCoachFlag = playerData['isCoach'] as bool? ?? false;
        final bool isCoach = isCoachFlag ||
            (role != null && (role.toLowerCase() == 'coach' || role.toLowerCase() == 'entrenador')) ||
            (teamCoachId != null && teamCoachId == player.id);

        final statRef = matchRef.collection('stats').doc(player.id);
        batch.set(statRef, {
          'playerId': player.id,
          'playerName': playerData['name'] ?? '',
          'minutos': 0,
          'goles': 0,
          'asistencias': 0,
          'amarillas': 0,
          'rojas': 0,
          'titular': false,
          'convocado': true,
          'isCoach': isCoach,
        });
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }
}
