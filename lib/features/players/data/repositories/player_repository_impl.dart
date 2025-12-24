import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/player_update.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';
import 'package:teampulse/features/players/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<Player>> watchTeamPlayers(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _playerFromDoc(doc)).toList();
    });
  }

  @override
  Stream<List<Sanction>> watchPendingSanctions(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('sanctions')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _sanctionFromDoc(doc)).toList();
    });
  }

  @override
  Future<bool> isCoach(String userId) async {
    if (userId.isEmpty) return false;
    final doc = await _firestore.collection('users').doc(userId).get();
    final role = (doc.data()?['role'] as String?)?.toLowerCase() ?? '';
    return role == 'entrenador' || role == 'coach';
  }

  @override
  Future<void> markSanctionServed({
    required String teamId,
    required String sanctionId,
    required String resolvedBy,
  }) async {
    final resolvedById = resolvedBy.isEmpty ? _auth.currentUser?.uid : resolvedBy;
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('sanctions')
        .doc(sanctionId)
        .update({
      'status': 'served',
      'resolvedAt': FieldValue.serverTimestamp(),
      if (resolvedById != null) 'resolvedBy': resolvedById,
    });
  }

  @override
  Future<void> markPlayerInjury({
    required String teamId,
    required String playerId,
    DateTime? estimatedReturn,
    String? injuryArea,
  }) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId)
        .update({
      'injured': true,
      'injuryReturnDate': estimatedReturn != null
          ? Timestamp.fromDate(estimatedReturn)
          : null,
      if (injuryArea != null && injuryArea.isNotEmpty) 'injuryArea': injuryArea,
    });
  }

  @override
  Future<void> clearPlayerInjury({
    required String teamId,
    required String playerId,
  }) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId)
        .update({
      'injured': false,
      'injuryReturnDate': FieldValue.delete(),
      'injuryArea': FieldValue.delete(),
    });
  }

  @override
  Future<void> setCaptain({
    required String teamId,
    required String playerId,
    required bool isCaptain,
  }) async {
    final playersCollection =
        _firestore.collection('teams').doc(teamId).collection('players');

    final batch = _firestore.batch();

    if (isCaptain) {
      final currentCaptains = await playersCollection.where('isCaptain', isEqualTo: true).get();
      for (final doc in currentCaptains.docs) {
        if (doc.id == playerId) continue;
        batch.update(doc.reference, {'isCaptain': false});
      }
    }

    batch.update(playersCollection.doc(playerId), {'isCaptain': isCaptain});

    await batch.commit();
  }

  @override
  Future<void> updatePlayerStats({
    required String teamId,
    required String playerId,
    required PlayerUpdate update,
  }) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId)
        .set(update.toJson(), SetOptions(merge: true));
  }

  Player _playerFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final injuryValue = data['injuryReturnDate'];
    DateTime? injuryDate;
    if (injuryValue is Timestamp) {
      injuryDate = injuryValue.toDate();
    } else if (injuryValue is DateTime) {
      injuryDate = injuryValue;
    }

    return Player(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: (data['role'] as String?) ?? '',
      position: (data['posicion'] as String?) ?? '',
      goals: _asInt(data['goles']),
      assists: _asInt(data['asistencias']),
      matches: _asInt(data['partidos']),
      minutes: _asInt(data['minutos']),
      yellowCards: _asInt(data['tarjetas_amarillas']),
      redCards: _asInt(data['tarjetas_rojas']),
      injured: data['injured'] == true,
      injuryReturnDate: injuryDate,
      injuryArea: data['injuryArea'] as String?,
      isCaptain: data['isCaptain'] == true,
      photoUrl: (data['photoUrl'] as String?) ?? '',
      teamId: (data['teamId'] as String?) ?? '',
    );
  }

  Sanction _sanctionFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final matchDateValue = data['matchDate'];
    DateTime? matchDate;
    if (matchDateValue is Timestamp) {
      matchDate = matchDateValue.toDate();
    } else if (matchDateValue is DateTime) {
      matchDate = matchDateValue;
    }

    return Sanction(
      id: doc.id,
      playerId: (data['playerId'] as String?) ?? '',
      playerName: (data['playerName'] as String?) ?? 'Jugador',
      opponent: (data['opponent'] as String?) ?? 'Rival',
      reason: (data['reason'] as String?) ?? 'Sanción',
      note: (data['notes'] as String?) ?? '',
      matchDate: matchDate,
      status: (data['status'] as String?) ?? 'pending',
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
