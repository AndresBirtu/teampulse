import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';
import 'package:teampulse/features/players/domain/entities/player_update.dart';
import 'package:teampulse/features/players/domain/repositories/player_repository.dart';
import 'package:teampulse/features/players/presentation/providers/player_repository_provider.dart';
import 'package:teampulse/features/players/presentation/state/players_state.dart';
import 'package:teampulse/features/players/presentation/viewmodels/players_view_model.dart';

void main() {
  const args = PlayersViewArgs(teamId: 'team_123', userId: 'coach_456');

  late _FakePlayerRepository fakeRepository;
  late ProviderContainer container;

  Future<void> flushMicrotasks() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Player buildPlayer({
    required String id,
    required String name,
    String role = 'Jugador',
    String position = 'Pivot',
    bool injured = false,
    DateTime? injuryReturnDate,
  }) {
    return Player(
      id: id,
      name: name,
      email: '$id@example.com',
      role: role,
      position: position,
      goals: 0,
      assists: 0,
      matches: 0,
      minutes: 0,
      yellowCards: 0,
      redCards: 0,
      injured: injured,
      injuryReturnDate: injuryReturnDate,
      photoUrl: '',
      teamId: args.teamId,
    );
  }

  Sanction buildSanction({
    required String id,
    required String playerId,
    String playerName = 'Jugador',
    String opponent = 'Rival FC',
  }) {
    return Sanction(
      id: id,
      playerId: playerId,
      playerName: playerName,
      opponent: opponent,
      reason: 'Roja directa',
      note: '',
      matchDate: DateTime(2024, 1, 10),
      status: 'pending',
    );
  }

  setUp(() {
    fakeRepository = _FakePlayerRepository(isCoachValue: true);
    container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() async {
    await fakeRepository.dispose();
    container.dispose();
  });

  test('builds initial state using repository coach flag', () async {
    final provider = playersViewModelProvider(args);
    final sub = container.listen(provider, (_, __) {});
    addTearDown(sub.close);

    final state = await container.read(provider.future);

    expect(state.teamId, args.teamId);
    expect(state.isCoach, isTrue);
    expect(state.players, isEmpty);
    expect(state.sanctions, isEmpty);
  });

  test('updates players and sanctions streams into derived state', () async {
    final provider = playersViewModelProvider(args);
    final sub = container.listen(provider, (_, __) {});
    addTearDown(sub.close);
    await container.read(provider.future);

    fakeRepository.emitPlayers([
      buildPlayer(id: 'a', name: 'Alex', position: 'Pivot'),
      buildPlayer(id: 'b', name: 'Bruno', position: 'Cierre', injured: true),
      buildPlayer(id: 'coach', name: 'DT', role: 'coach', position: ''),
    ]);
    fakeRepository.emitSanctions([
      buildSanction(id: 's1', playerId: 'b', playerName: 'Bruno'),
    ]);
    await flushMicrotasks();

    final current = container.read(provider).value!;

    expect(current.filteredPlayers.map((p) => p.id), ['a', 'b']);
    expect(current.availablePlayers.map((p) => p.id), ['a']);
    expect(current.injuredPlayers.map((p) => p.id), ['b']);
    expect(current.sanctionsByPlayerId.keys, contains('b'));
  });

  test('change sort and filter reflect in state snapshot', () async {
    final provider = playersViewModelProvider(args);
    final sub = container.listen(provider, (_, __) {});
    addTearDown(sub.close);
    await container.read(provider.future);

    fakeRepository.emitPlayers([
      buildPlayer(id: 'a', name: 'Zoe', position: 'Pivot'),
      buildPlayer(id: 'b', name: 'Ana', position: 'Portero'),
    ]);
    await flushMicrotasks();

    final controller = container.read(provider.notifier);
    controller.changeSort(PlayersSort.nameDesc);
    controller.changeFilter('Pivot');
    await flushMicrotasks();

    final current = container.read(provider).value!;
    expect(current.sort, PlayersSort.nameDesc);
    expect(current.filterPosition, 'Pivot');
    expect(current.filteredPlayers.map((p) => p.id), ['a']);
  });

  test('delegates markSanctionServed with view args context', () async {
    final provider = playersViewModelProvider(args);
    final sub = container.listen(provider, (_, __) {});
    addTearDown(sub.close);
    await container.read(provider.future);

    final controller = container.read(provider.notifier);
    await controller.markSanctionServed('sanction-42');

    expect(fakeRepository.lastServedSanctionId, 'sanction-42');
    expect(fakeRepository.lastServedTeamId, args.teamId);
    expect(fakeRepository.lastResolvedBy, args.userId);
  });
}

class _FakePlayerRepository implements PlayerRepository {
  _FakePlayerRepository({required this.isCoachValue});

  final bool isCoachValue;
  final _playersController = StreamController<List<Player>>.broadcast();
  final _sanctionsController = StreamController<List<Sanction>>.broadcast();

  String? lastServedTeamId;
  String? lastServedSanctionId;
  String? lastResolvedBy;

  void emitPlayers(List<Player> players) => _playersController.add(players);
  void emitSanctions(List<Sanction> sanctions) => _sanctionsController.add(sanctions);

  Future<void> dispose() async {
    await _playersController.close();
    await _sanctionsController.close();
  }

  @override
  Stream<List<Player>> watchTeamPlayers(String teamId) => _playersController.stream;

  @override
  Stream<List<Sanction>> watchPendingSanctions(String teamId) => _sanctionsController.stream;

  @override
  Future<bool> isCoach(String userId) async => isCoachValue;

  @override
  Future<void> markSanctionServed({
    required String teamId,
    required String sanctionId,
    required String resolvedBy,
  }) async {
    lastServedTeamId = teamId;
    lastServedSanctionId = sanctionId;
    lastResolvedBy = resolvedBy;
  }

  @override
  Future<void> markPlayerInjury({
    required String teamId,
    required String playerId,
    DateTime? estimatedReturn,
  }) async {}

  @override
  Future<void> clearPlayerInjury({
    required String teamId,
    required String playerId,
  }) async {}

  @override
  Future<void> updatePlayerStats({
    required String teamId,
    required String playerId,
    required PlayerUpdate update,
  }) async {}
}
