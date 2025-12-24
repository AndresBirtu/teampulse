import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';
import 'package:teampulse/features/matches/presentation/pages/create_match_page.dart';
import 'package:teampulse/features/matches/presentation/pages/lineup_builder_page.dart';
import 'package:teampulse/features/matches/presentation/pages/match_availability_page.dart';
import 'package:teampulse/features/matches/presentation/pages/match_stats_editor.dart';
import 'package:teampulse/features/matches/presentation/viewmodels/matches_view_model.dart';
import 'package:teampulse/theme/app_themes.dart';

class MatchesPage extends ConsumerWidget {
  final String teamId;
  const MatchesPage({required this.teamId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (teamId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("❌ Error: No se encontró el equipo")),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final primaryDark = context.primaryDarkColor;
    final onPrimary = colorScheme.onPrimary;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    final outline = colorScheme.outline;
    final surface = colorScheme.surface;
    final accent = colorScheme.secondary;
    final errorColor = colorScheme.error;

    final userId = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final viewArgs = MatchesViewArgs(teamId: teamId, userId: userId);
    final provider = matchesViewModelProvider(viewArgs);
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    final floatingActionButton = asyncState.maybeWhen(
      data: (state) {
        if (!state.isCoach) return null;
        return FloatingActionButton(
          backgroundColor: primary,
          elevation: 6,
          child: Icon(Icons.add, color: onPrimary, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateMatchPage(teamId: teamId)),
            );
          },
        );
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gestión de partidos",
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error cargando partidos: $error'),
        ),
        data: (state) {
          if (!state.hasMatches) {
            return const Center(child: Text("No hay partidos registrados"));
          }

          final matches = state.matches;
          final isCoach = state.isCoach;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchId = match.id;
              final matchNote = match.note.trim();

              final date = match.date;
              final formattedDate = date != null
                  ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                  : "Sin fecha";

              final isPlayed = match.played;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 4,
                shadowColor: (isPlayed ? outline : primary).withOpacity(0.25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? LinearGradient(
                            colors: [outline.withOpacity(0.15), surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [primary.withOpacity(0.08), primary.withOpacity(0.02)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isPlayed ? null : context.primaryGradient,
                        color: isPlayed ? outline : null,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPlayed ? outline : primary).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.sports_soccer, color: isPlayed ? primary : onPrimary, size: 26),
                    ),
                    title: Text(
                      "${match.teamA} vs ${match.teamB}", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPlayed ? textSecondary : textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formattedDate,
                                style: TextStyle(color: textSecondary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isPlayed) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events, size: 16, color: primaryDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${match.goalsTeamA} - ${match.goalsTeamB}',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (matchNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note_alt_outlined, size: 16, color: accent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  matchNote,
                                  style: TextStyle(color: textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _matchActionChip(
                              context: context,
                              icon: Icons.people,
                              tooltip: 'Convocatorias y disponibilidad',
                              color: primary,
                              onTap: () {
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MatchAvailabilityPage(
                                      teamId: teamId,
                                      matchId: matchId,
                                      isCoach: isCoach,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (isCoach)
                              _matchActionChip(
                                context: context,
                                icon: Icons.stacked_bar_chart,
                                tooltip: 'Estadísticas',
                                color: accent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MatchStatsEditor(teamId: teamId, matchId: matchId),
                                    ),
                                  );
                                },
                              ),
                            if (isCoach)
                              _matchActionChip(
                                context: context,
                                icon: Icons.sports_soccer_outlined,
                                tooltip: 'Formaciones',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LineupBuilderPage(teamId: teamId, matchId: matchId),
                                    ),
                                  );
                                },
                              ),
                            if (isCoach)
                              _matchActionChip(
                                context: context,
                                icon: Icons.note_alt_outlined,
                                tooltip: 'Anotaciones del partido',
                                color: accent,
                                onTap: () => _showMatchNoteEditor(
                                  context,
                                  viewModel,
                                  match,
                                ),
                              ),
                            if (isCoach)
                              _matchActionChip(
                                context: context,
                                icon: Icons.delete_forever,
                                tooltip: 'Eliminar partido',
                                color: errorColor,
                                onTap: () => _confirmDeleteMatch(
                                  context,
                                  viewModel,
                                  match,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  onTap: isCoach
                      ? () => _editMatchResult(
                            context: context,
                            viewModel: viewModel,
                            match: match,
                            activeColor: primary,
                          )
                      : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _matchActionChip({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: resolvedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: resolvedColor, size: 20),
        ),
      ),
    );
  }

  Future<void> _showMatchNoteEditor(
    BuildContext context,
    MatchesViewModel viewModel,
    TeamMatch match,
  ) async {
    final controller = TextEditingController(text: match.note.trim());
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anotaciones del partido',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Llegar 30 min antes, traer identificación...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(sheetCtx, ''),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Limpiar nota'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx, controller.text.trim()),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await viewModel.updateMatchNote(matchId: match.id, note: result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anotaciones actualizadas')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar las notas: $e')),
      );
    }
  }

  Future<void> _editMatchResult({
    required BuildContext context,
    required MatchesViewModel viewModel,
    required TeamMatch match,
    required Color activeColor,
  }) async {
    final TextEditingController aController = TextEditingController(text: match.goalsTeamA.toString());
    final TextEditingController bController = TextEditingController(text: match.goalsTeamB.toString());
    bool played = match.played;

    final result = await showDialog<_ResultDialogData>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            return AlertDialog(
              title: const Text('Editar resultado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: played,
                    onChanged: (v) => setState(() => played = v),
                    title: const Text('Marcado como jugado'),
                    activeColor: activeColor,
                  ),
                  if (played) ...[
                    TextField(
                      controller: aController,
                      decoration: const InputDecoration(labelText: 'Goles Equipo A'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bController,
                      decoration: const InputDecoration(labelText: 'Goles Equipo B'),
                      keyboardType: TextInputType.number,
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx2).pop(null), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx2).pop(
                      _ResultDialogData(
                        played: played,
                        goalsTeamA: int.tryParse(aController.text) ?? 0,
                        goalsTeamB: int.tryParse(bController.text) ?? 0,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    aController.dispose();
    bController.dispose();

    if (result == null) return;

    try {
      await viewModel.updateMatchResult(
        match: match,
        played: result.played,
        goalsTeamA: result.played ? result.goalsTeamA : null,
        goalsTeamB: result.played ? result.goalsTeamB : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resultado actualizado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteMatch(
    BuildContext context,
    MatchesViewModel viewModel,
    TeamMatch match,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: const Text('¿Eliminar este partido del historial? Esta acción puede revertir estadísticas agregadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await viewModel.deleteMatch(match);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Partido eliminado')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error eliminando: $e')));
    }
  }
}

class _ResultDialogData {
  const _ResultDialogData({
    required this.played,
    required this.goalsTeamA,
    required this.goalsTeamB,
  });

  final bool played;
  final int goalsTeamA;
  final int goalsTeamB;
}