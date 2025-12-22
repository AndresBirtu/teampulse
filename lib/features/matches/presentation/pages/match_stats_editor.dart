import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/matches/domain/entities/player_match_stat.dart';
import 'package:teampulse/features/matches/presentation/state/match_stats_state.dart';
import 'package:teampulse/features/matches/presentation/viewmodels/match_stats_view_model.dart';

typedef _GuardedAction = Future<bool> Function(Future<void> Function() action, {String? successMessage});

class MatchStatsEditor extends ConsumerWidget {
  const MatchStatsEditor({
    required this.teamId,
    required this.matchId,
    this.matchDurationMinutes,
    super.key,
  });

  final String teamId;
  final String matchId;
  final int? matchDurationMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = MatchStatsViewArgs(
      teamId: teamId,
      matchId: matchId,
      matchDurationMinutes: matchDurationMinutes ?? 90,
    );
    final provider = matchStatsViewModelProvider(args);
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    Future<bool> guard(Future<void> Function() action, {String? successMessage}) async {
      try {
        await action();
        if (successMessage != null && successMessage.isNotEmpty) {
          _showSnack(context, successMessage);
        }
        return true;
      } catch (error) {
        _showError(context, error);
        return false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas del partido'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(error: error, onRetry: () => ref.refresh(provider)),
        data: (state) => _MatchStatsBody(
          state: state,
          guardAction: guard,
          viewModel: viewModel,
          onSave: () async {
            final success = await guard(() => viewModel.saveChanges(), successMessage: 'Cambios guardados ✅');
            if (success && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          onApply: () => guard(() => viewModel.applyStats(), successMessage: 'Estadísticas aplicadas al plantel'),
          onForceReapply: () => _confirmForceReapply(context, guard, viewModel),
        ),
      ),
    );
  }

  static Future<bool> _confirmForceReapply(BuildContext context, _GuardedAction guard, MatchStatsViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forzar re-aplicar'),
        content: const Text('Se revertirán y volverán a aplicarse las estadísticas en los jugadores. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (confirm != true) return false;
    return guard(() => viewModel.forceReapplyStats(), successMessage: 'Estadísticas reaplicadas correctamente');
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ocurrió un error: $error')),
    );
  }
}

class _MatchStatsBody extends StatelessWidget {
  const _MatchStatsBody({
    required this.state,
    required this.guardAction,
    required this.viewModel,
    required this.onSave,
    required this.onApply,
    required this.onForceReapply,
  });

  final MatchStatsState state;
  final _GuardedAction guardAction;
  final MatchStatsViewModel viewModel;
  final Future<void> Function() onSave;
  final Future<bool> Function() onApply;
  final Future<bool> Function() onForceReapply;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    if (state.titulares.isNotEmpty) {
      sections.addAll(_buildSection(context, 'Titulares', state.titulares));
    }
    if (state.suplentes.isNotEmpty) {
      sections.addAll(_buildSection(context, 'Suplentes', state.suplentes));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (!state.hasStats)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Text('No hay jugadores disponibles en esta hoja de estadísticas'),
          ),
        ...sections,
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ActionsPanel(
            state: state,
            onSave: onSave,
            onApply: onApply,
            onForceReapply: onForceReapply,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildSection(BuildContext context, String title, List<PlayerMatchStat> players) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          '$title (${players.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      ...players.map(
        (stat) => _PlayerCard(
          stat: stat,
          state: state,
          guardAction: guardAction,
          viewModel: viewModel,
        ),
      ),
    ];
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.stat,
    required this.state,
    required this.guardAction,
    required this.viewModel,
  });

  final PlayerMatchStat stat;
  final MatchStatsState state;
  final _GuardedAction guardAction;
  final MatchStatsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConvocado = stat.convocado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stat.playerName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Text('Convocado'),
                Switch(
                  value: isConvocado,
                  onChanged: (value) => guardAction(() => viewModel.toggleConvocado(stat.playerId, value)),
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(stat.titular ? '11 inicial' : 'Suplente'),
                  selected: stat.titular,
                  onSelected: stat.convocado ? (selected) => guardAction(() => viewModel.toggleStarter(stat.playerId, selected)) : null,
                  selectedColor: Colors.green[200],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: isConvocado ? 1 : 0.5,
              child: AbsorbPointer(
                absorbing: !isConvocado,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCounter(
                            label: '⚽ Goles',
                            value: stat.goals,
                            onAdd: () => guardAction(() => viewModel.adjustGoals(stat.playerId, 1)),
                            onRemove: () => guardAction(() => viewModel.adjustGoals(stat.playerId, -1)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCounter(
                            label: '🎁 Asist.',
                            value: stat.assists,
                            onAdd: () => guardAction(() => viewModel.adjustAssists(stat.playerId, 1)),
                            onRemove: () => guardAction(() => viewModel.adjustAssists(stat.playerId, -1)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CardSelector(
                            yellowCards: stat.yellowCards,
                            redCards: stat.redCards,
                            onAddYellow: () => guardAction(() => viewModel.adjustYellowCards(stat.playerId, 1)),
                            onRemoveYellow: () => guardAction(() => viewModel.adjustYellowCards(stat.playerId, -1)),
                            onAddRed: () => guardAction(
                              () => viewModel.addRedCard(stat.playerId),
                              successMessage: 'Sanción registrada para ${stat.playerName}',
                            ),
                            onRemoveRed: () => guardAction(
                              () => viewModel.removeRedCard(stat.playerId),
                              successMessage: 'Sanción eliminada para ${stat.playerName}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MinutesSlider(
                      minutes: stat.minutes,
                      maxMinutes: state.matchDuration,
                      onChanged: (value) => guardAction(() => viewModel.setMinutes(stat.playerId, value)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  const _StatCounter({
    required this.label,
    required this.value,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int value;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: onRemove,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardSelector extends StatelessWidget {
  const _CardSelector({
    required this.yellowCards,
    required this.redCards,
    required this.onAddYellow,
    required this.onRemoveYellow,
    required this.onAddRed,
    required this.onRemoveRed,
  });

  final int yellowCards;
  final int redCards;
  final VoidCallback onAddYellow;
  final VoidCallback onRemoveYellow;
  final VoidCallback onAddRed;
  final VoidCallback onRemoveRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text('Tarjetas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _CardBadge(color: Colors.yellow, value: yellowCards, textColor: Colors.black),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: yellowCards > 0 ? onRemoveYellow : null,
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: onAddYellow,
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _CardBadge(color: Colors.red, value: redCards, textColor: Colors.white),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: redCards > 0 ? onRemoveRed : null,
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: onAddRed,
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({
    required this.color,
    required this.value,
    required this.textColor,
  });

  final Color color;
  final int value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}

class _MinutesSlider extends StatelessWidget {
  const _MinutesSlider({
    required this.minutes,
    required this.maxMinutes,
    required this.onChanged,
  });

  final int minutes;
  final int maxMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('⏱ Minutos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('$minutes min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Slider(
          value: minutes.toDouble(),
          min: 0,
          max: maxMinutes.toDouble(),
          divisions: maxMinutes == 0 ? null : maxMinutes,
          label: '$minutes',
          onChanged: (value) => onChanged(value.toInt()),
        ),
      ],
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({
    required this.state,
    required this.onSave,
    required this.onApply,
    required this.onForceReapply,
  });

  final MatchStatsState state;
  final Future<void> Function() onSave;
  final Future<bool> Function() onApply;
  final Future<bool> Function() onForceReapply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: state.isApplying || !state.canApplyStats ? null : () => onApply(),
                child: state.isApplying
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Aplicar a jugadores'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: state.isApplying || !state.canForceReapply ? null : () => onForceReapply(),
                child: state.isApplying
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Forzar re-aplicar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
            onPressed: state.isSaving ? null : onSave,
            child: state.isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No se pudieron cargar las estadísticas: $error'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
