import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';
import 'package:teampulse/features/players/presentation/pages/edit_player_page.dart';
import 'package:teampulse/features/players/presentation/state/players_state.dart';
import 'package:teampulse/features/players/presentation/viewmodels/players_view_model.dart';
import 'package:teampulse/features/players/presentation/widgets/player_card.dart';
import 'package:teampulse/features/players/presentation/widgets/players_filter_panel.dart';
import 'package:teampulse/features/players/presentation/widgets/players_injuries_panel.dart';
import 'package:teampulse/features/players/presentation/widgets/players_injury_dialog.dart';
import 'package:teampulse/features/players/presentation/widgets/players_sanctions_panel.dart';

class PlayersPage extends ConsumerWidget {
  const PlayersPage({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver los jugadores.')),
      );
    }

    final args = PlayersViewArgs(teamId: teamId, userId: userId);
    final provider = playersViewModelProvider(args);
    final asyncState = ref.watch(provider);
    final controller = ref.watch(provider.notifier);

    return asyncState.when(
      data: (state) => _PlayersViewBody(
        state: state,
        controller: controller,
        teamId: teamId,
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error al cargar jugadores: $error')),
      ),
    );
  }
}

class _PlayersViewBody extends StatelessWidget {
  const _PlayersViewBody({
    required this.state,
    required this.controller,
    required this.teamId,
  });

  final PlayersState state;
  final PlayersViewModel controller;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final players = state.filteredPlayers;
    final sanctionMap = state.sanctionsByPlayerId;
    final injuredList = state.filterPosition.isEmpty ? state.injuredPlayers : const <Player>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jugadores del equipo'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: Column(
        children: [
          PlayersSanctionsPanel(
            sanctions: state.sanctions,
            isCoach: state.isCoach,
            onServeSanction: (sanction) => _confirmServeSanction(context, sanction),
          ),
          if (state.sanctions.isNotEmpty) const Divider(height: 1),
          PlayersFilterPanel(state: state, controller: controller),
          const Divider(height: 1),
          if (injuredList.isNotEmpty && state.filterPosition.isEmpty)
            PlayersInjuriesPanel(injuredPlayers: injuredList),
          if (injuredList.isNotEmpty && state.filterPosition.isEmpty)
            const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final sanction = sanctionMap[player.id];
                return PlayerCard(
                  player: player,
                  sanction: sanction,
                  isCoach: state.isCoach,
                  onServeSanction: sanction == null
                      ? null
                      : () => _confirmServeSanction(context, sanction),
                  onToggleInjury: () => showPlayerInjuryDialog(
                    context: context,
                    player: player,
                    controller: controller,
                  ),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPlayerPage(
                        teamId: teamId,
                        playerId: player.id,
                        playerData: player.toEditableMap(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmServeSanction(BuildContext context, Sanction sanction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar sanción cumplida'),
        content: Text('Confirmas que ${sanction.playerName} ya cumplió su sanción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Marcar cumplida'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await controller.markSanctionServed(sanction.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sanción marcada como cumplida')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo actualizar la sanción: $e')),
          );
        }
      }
    }
  }

}


