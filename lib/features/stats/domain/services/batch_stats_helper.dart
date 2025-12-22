import 'package:cloud_firestore/cloud_firestore.dart';

/// Aplica actualizaciones de estadísticas a múltiples jugadores en lote.
/// Usa FieldValue.increment para asegurar consistencia y atomicidad.
///
/// Parámetro:
/// - teamId: ID del equipo
/// - playersStats: Map<playerId, Map<statField, incrementValue>>
///   Ejemplo: {'player1': {'goles': 2, 'minutos': 90}, 'player2': {'asistencias': 1}}
Future<void> applyMatchStats(String teamId, Map<String, Map<String, dynamic>> playersStats) async {
  if (playersStats.isEmpty) return;

  final firestore = FirebaseFirestore.instance;
  final teamRef = firestore.collection('teams').doc(teamId);

  for (final entry in playersStats.entries) {
    final playerId = entry.key;
    final stats = entry.value;
    final playerRef = teamRef.collection('players').doc(playerId);

    final updateData = <String, dynamic>{};

    // Mapea los campos que pueden incrementarse
    if (stats.containsKey('goles') && stats['goles'] != 0) {
      updateData['goles'] = FieldValue.increment(stats['goles'] as int);
    }
    if (stats.containsKey('asistencias') && stats['asistencias'] != 0) {
      updateData['asistencias'] = FieldValue.increment(stats['asistencias'] as int);
    }
    if (stats.containsKey('minutos') && stats['minutos'] != 0) {
      updateData['minutos'] = FieldValue.increment(stats['minutos'] as int);
    }
    if (stats.containsKey('tarjetas_amarillas') && stats['tarjetas_amarillas'] != 0) {
      updateData['tarjetas_amarillas'] = FieldValue.increment(stats['tarjetas_amarillas'] as int);
    }
    if (stats.containsKey('tarjetas_rojas') && stats['tarjetas_rojas'] != 0) {
      updateData['tarjetas_rojas'] = FieldValue.increment(stats['tarjetas_rojas'] as int);
    }
    if (stats.containsKey('partidos') && stats['partidos'] != 0) {
      updateData['partidos'] = FieldValue.increment(stats['partidos'] as int);
    }

    if (updateData.isNotEmpty) {
      try {
        // Intenta actualizar si el documento existe
        await playerRef.update(updateData);
      } catch (e) {
        // Si no existe, crea el documento con los valores iniciales (sin increment)
        final initialData = <String, dynamic>{};
        stats.forEach((key, value) {
          if (value != 0) initialData[key] = value;
        });
        if (initialData.isNotEmpty) {
          await playerRef.set(initialData, SetOptions(merge: true));
        }
      }
    }
  }
}

/// Actualiza un rango de jugadores con el mismo valor (no incremento).
/// Útil para ajustes puntuales (ej. establecer posición, restaurar algo).
///
/// Parámetro:
/// - teamId: ID del equipo
/// - playerIds: Lista de IDs de jugadores
/// - updateData: Map<field, value> a aplicar a todos
Future<void> bulkUpdatePlayers(
  String teamId,
  List<String> playerIds,
  Map<String, dynamic> updateData,
) async {
  if (playerIds.isEmpty || updateData.isEmpty) return;

  final firestore = FirebaseFirestore.instance;
  final teamRef = firestore.collection('teams').doc(teamId);

  for (final playerId in playerIds) {
    final playerRef = teamRef.collection('players').doc(playerId);
    try {
      await playerRef.update(updateData);
    } catch (e) {
      // Si no existe, crea el documento
      await playerRef.set(updateData, SetOptions(merge: true));
    }
  }
}

/// Incrementa un mismo campo en múltiples jugadores.
/// Útil para correcciones rápidas (ej. "+2 goles a estos 3 jugadores").
///
/// Parámetro:
/// - teamId: ID del equipo
/// - playerIds: Lista de IDs de jugadores
/// - field: Nombre del campo (ej. 'goles', 'minutos')
/// - amount: Cantidad a incrementar (puede ser negativo para decrementar)
Future<void> incrementPlayersField(
  String teamId,
  List<String> playerIds,
  String field,
  int amount,
) async {
  if (playerIds.isEmpty || amount == 0) return;

  final firestore = FirebaseFirestore.instance;
  final teamRef = firestore.collection('teams').doc(teamId);

  for (final playerId in playerIds) {
    final playerRef = teamRef.collection('players').doc(playerId);
    try {
      // Intenta actualizar (el documento debe existir)
      await playerRef.update({field: FieldValue.increment(amount)});
    } catch (e) {
      // Si no existe, crea el documento con el valor inicial
      await playerRef.set({field: amount}, SetOptions(merge: true));
    }
  }
}
