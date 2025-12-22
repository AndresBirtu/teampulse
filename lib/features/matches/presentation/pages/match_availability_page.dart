import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/matches/domain/entities/match_availability.dart';
import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';
import 'package:teampulse/features/matches/presentation/state/match_availability_state.dart';
import 'package:teampulse/features/matches/presentation/viewmodels/match_availability_view_model.dart';

class MatchAvailabilityPage extends ConsumerWidget {
  const MatchAvailabilityPage({
    required this.teamId,
    required this.matchId,
    required this.isCoach,
    super.key,
  });

  final String teamId;
  final String matchId;
  final bool isCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final args = MatchAvailabilityViewArgs(
      teamId: teamId,
      matchId: matchId,
      userId: userId,
      isCoach: isCoach,
    );

    final provider = matchAvailabilityViewModelProvider(args);
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return asyncState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.tr('loading'))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('availability'))),
        body: Center(child: Text(context.tr('match_availability_load_error', args: ['$error']))),
      ),
      data: (state) {
        final match = state.match;
        if (match == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('availability'))),
            body: Center(child: Text(context.tr('match_not_found'))),
          );
        }

        final userAvailability = state.availabilityFor(userId);
        final isUserConvocado = state.isPlayerConvocado(userId);

        return Scaffold(
          appBar: AppBar(
            title: Text(isCoach ? context.tr('callups') : context.tr('availability')),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MatchInfoHeader(match: match),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CoachMessageCard(
                    isCoach: state.isCoach,
                    message: state.coachMessage,
                    onEdit: state.isCoach
                        ? () => _editCoachMessage(context, viewModel, state.coachMessage)
                        : null,
                  ),
                ),
                if (!state.isCoach)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('availability_attend_question'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _AvailabilityActions(
                          currentStatus: userAvailability?.status ?? MatchAvailabilityStatus.unknown,
                          onTap: (status) => _handleAvailabilityAction(
                            context,
                            viewModel,
                            status,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('callup_status_section_title'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _ConvocationStatusCard(isConvocado: isUserConvocado),
                      ],
                    ),
                  ),
                if (state.isCoach)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('callup_manage_title'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('callup_manage_subtitle'),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        _CoachPlayersList(
                          players: state.squadPlayers,
                          availabilityByPlayer: state.availabilityByPlayerId,
                          convocados: match.convocados,
                          onToggle: (playerId, value) => _handleToggleConvocado(
                            context,
                            viewModel,
                            playerId,
                            value,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.tr('players_availability_section'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _AvailabilitySummary(
                  availabilities: state.filteredAvailabilities,
                  playersById: state.playersById,
                  convocados: match.convocados,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MatchInfoHeader extends StatelessWidget {
  const _MatchInfoHeader({required this.match});

  final TeamMatch match;

  @override
  Widget build(BuildContext context) {
    final date = match.date;
    final formattedDate = date != null
      ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
      : context.tr('match_no_date');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('match_vs_line', args: [match.teamA, match.teamB]),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(formattedDate, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _CoachMessageCard extends StatelessWidget {
  const _CoachMessageCard({
    required this.isCoach,
    required this.message,
    this.onEdit,
  });

  final bool isCoach;
  final String? message;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCoach ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCoach ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message,
                color: isCoach ? Colors.blue : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('coach_message_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (message != null && message!.isNotEmpty)
            Text(
              message!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            )
          else
            Text(
              isCoach
                  ? context.tr('coach_message_edit_hint_coach')
                  : context.tr('coach_message_edit_hint_player'),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvailabilityActions extends StatelessWidget {
  const _AvailabilityActions({
    required this.currentStatus,
    required this.onTap,
  });

  final MatchAvailabilityStatus currentStatus;
  final ValueChanged<MatchAvailabilityStatus> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: Text(context.tr('yes')),
            style: _buttonStyle(context, Colors.green, currentStatus == MatchAvailabilityStatus.yes),
            onPressed: () => onTap(MatchAvailabilityStatus.yes),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.help_outline),
            label: Text(context.tr('maybe')),
            style: _buttonStyle(context, Colors.orange, currentStatus == MatchAvailabilityStatus.maybe),
            onPressed: () => onTap(MatchAvailabilityStatus.maybe),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel),
            label: Text(context.tr('no')),
            style: _buttonStyle(context, Colors.red, currentStatus == MatchAvailabilityStatus.no),
            onPressed: () => onTap(MatchAvailabilityStatus.no),
          ),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle(BuildContext context, Color color, bool isSelected) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? color : Colors.grey[300],
      foregroundColor: isSelected ? Colors.white : Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }
}

class _ConvocationStatusCard extends StatelessWidget {
  const _ConvocationStatusCard({required this.isConvocado});

  final bool isConvocado;

  @override
  Widget build(BuildContext context) {
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
                    ? context.tr('callup_status_called')
                    : context.tr('callup_status_pending'),
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
}

class _CoachPlayersList extends StatelessWidget {
  const _CoachPlayersList({
    required this.players,
    required this.availabilityByPlayer,
    required this.convocados,
    required this.onToggle,
  });

  final List<MatchPlayer> players;
  final Map<String, MatchAvailability> availabilityByPlayer;
  final List<String> convocados;
  final void Function(String playerId, bool isConvocado) onToggle;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Text(context.tr('no_players'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final availability = availabilityByPlayer[player.id];
        final isConvocado = convocados.contains(player.id);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: CheckboxListTile(
            value: isConvocado,
            onChanged: (value) => onToggle(player.id, value ?? false),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: _AvailabilityChip(status: availability?.status ?? MatchAvailabilityStatus.unknown),
            activeColor: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}

class _AvailabilitySummary extends StatelessWidget {
  const _AvailabilitySummary({
    required this.availabilities,
    required this.playersById,
    required this.convocados,
  });

  final List<MatchAvailability> availabilities;
  final Map<String, MatchPlayer> playersById;
  final List<String> convocados;

  @override
  Widget build(BuildContext context) {
    if (availabilities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          context.tr('availability_summary_empty'),
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: availabilities.length,
      itemBuilder: (context, index) {
        final availability = availabilities[index];
        final player = playersById[availability.playerId];
        if (player != null && player.isCoach) {
          return const SizedBox.shrink();
        }

        final isConvocado = convocados.contains(availability.playerId);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: _statusIcon(availability.status),
            title: Text(availability.playerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvailabilityChip(status: availability.status),
                if (availability.reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          availability.reason,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: isConvocado
                ? Chip(
                    label: Text(context.tr('called_up_label'), style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green,
                    labelStyle: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
        );
      },
    );
  }

  static Icon _statusIcon(MatchAvailabilityStatus status) {
    switch (status) {
      case MatchAvailabilityStatus.yes:
        return const Icon(Icons.check_circle, color: Colors.green);
      case MatchAvailabilityStatus.maybe:
        return const Icon(Icons.help_outline, color: Colors.orange);
      case MatchAvailabilityStatus.no:
        return const Icon(Icons.cancel, color: Colors.red);
      case MatchAvailabilityStatus.unknown:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.status});

  final MatchAvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    late IconData icon;

    switch (status) {
      case MatchAvailabilityStatus.yes:
        color = Colors.green;
        label = context.tr('available');
        icon = Icons.check_circle;
        break;
      case MatchAvailabilityStatus.maybe:
        color = Colors.orange;
        label = context.tr('maybe');
        icon = Icons.help_outline;
        break;
      case MatchAvailabilityStatus.no:
        color = Colors.red;
        label = context.tr('not_available');
        icon = Icons.cancel;
        break;
      case MatchAvailabilityStatus.unknown:
        color = Colors.grey;
        label = context.tr('availability_unknown');
        icon = Icons.help_outline;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

Future<void> _handleAvailabilityAction(
  BuildContext context,
  MatchAvailabilityViewModel viewModel,
  MatchAvailabilityStatus status,
) async {
  String? reason;
  if (status == MatchAvailabilityStatus.no || status == MatchAvailabilityStatus.maybe) {
    reason = await _showReasonDialog(context, status);
    if (reason == null) return;
  }

  try {
    await viewModel.updateAvailability(status: status, reason: reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('availability_updated'))),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('error_with_message', args: ['$error']))),
    );
  }
}

Future<void> _handleToggleConvocado(
  BuildContext context,
  MatchAvailabilityViewModel viewModel,
  String playerId,
  bool isConvocado,
) async {
  try {
    await viewModel.toggleConvocado(playerId, isConvocado);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(isConvocado ? 'callup_marked' : 'callup_unmarked'),
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('error_with_message', args: ['$error']))),
    );
  }
}

Future<void> _editCoachMessage(
  BuildContext context,
  MatchAvailabilityViewModel viewModel,
  String? currentMessage,
) async {
  final controller = TextEditingController(text: currentMessage ?? '');
  final result = await showDialog<_CoachMessageDialogResult>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.tr('coach_message_dialog_title')),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: context.tr('coach_message_hint'),
            border: const OutlineInputBorder(),
            helperText: context.tr('coach_message_helper'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('cancel')),
          ),
          if (currentMessage != null && currentMessage.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                const _CoachMessageDialogResult.delete(),
              ),
              child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () {
              final message = controller.text.trim();
              if (message.isEmpty) return;
              Navigator.of(dialogContext).pop(_CoachMessageDialogResult.save(message));
            },
            child: Text(context.tr('save')),
          ),
        ],
      );
    },
  );

  if (result == null) return;

  try {
    await viewModel.updateCoachMessage(result.delete ? null : result.message);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(result.delete ? 'coach_message_deleted' : 'coach_message_saved'),
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('coach_message_save_error', args: ['$error']))),
    );
  }
}

Future<String?> _showReasonDialog(
  BuildContext context,
  MatchAvailabilityStatus status,
) {
  final controller = TextEditingController();
  final title = status == MatchAvailabilityStatus.no
      ? context.tr('availability_reason_absent_title')
      : context.tr('availability_reason_maybe_title');
  final hint = status == MatchAvailabilityStatus.no
      ? context.tr('availability_reason_absent_hint')
      : context.tr('availability_reason_maybe_hint');

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLength: 100,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: Text(context.tr('skip')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(context.tr('save')),
          ),
        ],
      );
    },
  );
}

class _CoachMessageDialogResult {
  const _CoachMessageDialogResult._(this.message, this.delete);

  const _CoachMessageDialogResult.save(String message)
      : this._(message, false);

  const _CoachMessageDialogResult.delete()
      : this._(null, true);

  final String? message;
  final bool delete;
}
