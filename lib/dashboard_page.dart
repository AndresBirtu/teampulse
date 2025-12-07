import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:teampulse/home_page.dart';
import 'match_page.dart';
import 'players_page.dart';
import 'full_stats_page.dart';
import 'team_stats_page.dart';
import 'trainings_page.dart';
import 'match_availability_page.dart';
import 'calendar_page.dart';
import 'theme/app_colors.dart';
import 'coach_profile_page.dart';
import 'theme/app_themes.dart';
import 'services/preferences_service.dart';

import 'player_profile_page.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription<DocumentSnapshot>? _teamThemeSubscription;
  String? _listeningTeamId;
  ThemeOption? _lastSyncedTheme;

  @override
  void initState() {
    super.initState();
    _lastSyncedTheme = PreferencesService.getSelectedTheme();
  }

  @override
  void dispose() {
    _teamThemeSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToTeamTheme(String teamId) {
    if (teamId.isEmpty) return;
    if (_listeningTeamId == teamId && _teamThemeSubscription != null) return;

    _teamThemeSubscription?.cancel();
    _listeningTeamId = teamId;
    _teamThemeSubscription = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .snapshots()
        .listen((snapshot) {
      final themeName = snapshot.data()?['theme'] as String?;
      if (themeName == null) return;
      try {
        final option = ThemeOption.values.byName(themeName);
        if (_lastSyncedTheme == option) return;
        _lastSyncedTheme = option;
        PreferencesService.setSelectedTheme(option);
      } catch (_) {
        // Ignorar valores inválidos para no romper la experiencia del usuario
      }
    });
  }
  
  void _showInviteDialog(BuildContext context, String teamId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar jugador'),
        content: const Text('Elige cómo quieres invitar al jugador'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showInviteLinkDialog(context, teamId);
            },
            child: const Text('Generar enlace'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showInviteByEmailDialog(context, teamId);
            },
            child: const Text('Invitar por email'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showInviteLinkDialog(BuildContext context, String teamId) async {
    try {
      final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
      final teamCode = teamDoc.exists ? (teamDoc.data()?['teamCode'] ?? '') : '';
      final link = 'https://teampulse.app/join?teamCode=$teamCode';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enlace de invitación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(link),
              const SizedBox(height: 12),
              const Text('Copia y comparte este enlace con los jugadores.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado al portapapeles')));
                }
              },
              child: const Text('Copiar enlace'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showInviteByEmailDialog(BuildContext context, String teamId) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar por email'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'Email del jugador'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un email válido')));
                return;
              }
              try {
                final usersSnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
                if (usersSnapshot.docs.isEmpty) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
                  return;
                }
                final userId = usersSnapshot.docs.first.id;
                await FirebaseFirestore.instance.collection('teams').doc(teamId).collection('players').doc(userId).set({
                  'name': usersSnapshot.docs.first['name'] ?? 'Jugador',
                  'email': email,
                  'role': 'jugador',
                  'goles': 0,
                  'asistencias': 0,
                  'posicion': '',
                  'partidos': 0,
                  'minutos': 0,
                  'tarjetas_amarillas': 0,
                  'tarjetas_rojas': 0,
                  'teamId': teamId,
                }, SetOptions(merge: true));

                await FirebaseFirestore.instance.collection('users').doc(userId).set({'teamId': teamId}, SetOptions(merge: true));

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jugador invitado correctamente ✅')));
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Invitar'),
          ),
        ],
      ),
    );
  }

  Widget _managementButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Gradient? gradient,
    Color? shadowColor,
  }) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final backgroundGradient = gradient ?? context.primaryGradient;
    final resolvedShadow = shadowColor ?? context.primaryColor.withOpacity(0.28);

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: resolvedShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: Icon(icon, color: onPrimary, size: 24),
        label: Text(
          label,
          style: TextStyle(color: onPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Gradient _secondaryButtonGradient(BuildContext context) {
    final secondary = context.secondaryColor;
    return LinearGradient(
      colors: [secondary, secondary.withOpacity(0.85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildCoachSanctionsPanel(String teamId, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('sanctions')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final primary = theme.colorScheme.primary;
        final onPrimary = theme.colorScheme.onPrimary;

        return Card(
          margin: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: context.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.gavel, color: onPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sanciones por roja',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final playerName = data['playerName'] ?? 'Jugador';
                  final opponent = data['opponent'] ?? '';
                  final reason = data['reason'] ?? 'Tarjeta roja';
                  final note = (data['notes'] ?? '').toString();
                  final matchDate = (data['matchDate'] as Timestamp?)?.toDate();
                  final dateStr = matchDate != null
                      ? '${matchDate.day}/${matchDate.month}/${matchDate.year}'
                      : 'Fecha no registrada';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withOpacity(0.15),
                          child: Icon(Icons.person, color: primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerName,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text('vs $opponent • $dateStr', style: theme.textTheme.bodySmall),
                              Text('Motivo: $reason', style: theme.textTheme.bodySmall),
                              if (note.isNotEmpty)
                                Text('Nota del partido: $note', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check_circle, color: theme.colorScheme.secondary),
                          tooltip: 'Marcar como cumplida',
                          onPressed: () => _markSanctionServed(teamId, doc.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerSanctionAlert(String teamId, String playerId, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('sanctions')
          .where('status', isEqualTo: 'pending')
          .where('playerId', isEqualTo: playerId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final opponent = data['opponent'] ?? 'un partido oficial';
        final warningColor = theme.colorScheme.error;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: warningColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: warningColor.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: warningColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tienes una sanción activa',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Por la última tarjeta roja vs $opponent. Consulta con tu entrenador antes de volver a jugar.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markSanctionServed(String teamId, String sanctionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('sanctions')
          .doc(sanctionId)
          .update({
        'status': 'served',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sanción actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la sanción: $e')),
      );
    }
  }

  Future<void> _showProfileMenu() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snapshot.data() ?? {};
      final role = (data['role'] as String?)?.toLowerCase() ?? '';
      final teamId = data['teamId'] as String?;
      final isCoach = role == 'entrenador' || role == 'coach';

      if (!mounted) return;

      if (isCoach) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CoachProfilePage()),
        );
      } else if (teamId != null && teamId.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfilePage(teamId: teamId, playerId: uid),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró tu equipo para abrir el perfil.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final primaryDark = context.primaryDarkColor;
    final secondary = context.secondaryColor;
    final onPrimary = colorScheme.onPrimary;
    final textPrimary = theme.textTheme.titleLarge?.color ?? Colors.black87;

    if (uid == null) {
      return const Center(child: Text("Usuario no encontrado"));
    }

    final userStream = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil y preferencias',
            onPressed: _showProfileMenu,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Cerrar sesión"),
                  content: const Text(
                    "¿Estás seguro de que quieres cerrar sesión?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(ctx).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text("Salir"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final role = userData["role"] ?? "jugador";
          final teamId = userData["teamId"] ?? "";
          _subscribeToTeamTheme(teamId);

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Theme.of(context).primaryColor,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Hola, ${userData["name"] ?? "Usuario"} 👋",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Next match card with animation - visible at the top for all users
                _NextMatchCard(teamId: teamId),
                if (role == 'entrenador' || role == 'coach')
                  _buildCoachSanctionsPanel(teamId, theme)
                else
                  _buildPlayerSanctionAlert(teamId, uid, theme),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("teams")
                      .doc(teamId)
                      .collection("players")
                      .doc(uid)
                      .snapshots(),
                  builder: (context, statsSnapshot) {
                    if (!statsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final statsData =
                        statsSnapshot.data!.data() as Map<String, dynamic>? ??
                        {};

                    return Column(
                      children: [
                        if (role == "entrenador")
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('teams')
                                .doc(teamId)
                                .collection('matches')
                                .snapshots(),
                            builder: (context, matchSnapshot) {
                              int currentStreak = 0;
                              DateTime? nextMatchDate;
                              
                              if (matchSnapshot.hasData) {
                                final matches = matchSnapshot.data?.docs ?? [];
                                
                                // Sort matches by date
                                final sortedMatches = matches.map((m) {
                                  final data = m.data() as Map<String, dynamic>?;
                                  return {'doc': m, 'data': data};
                                }).toList()
                                  ..sort((a, b) {
                                    final dataA = a['data'] as Map<String, dynamic>?;
                                    final dataB = b['data'] as Map<String, dynamic>?;
                                    final dateA = (dataA?['date'] as Timestamp?)?.toDate() ?? DateTime(1970);
                                    final dateB = (dataB?['date'] as Timestamp?)?.toDate() ?? DateTime(1970);
                                    return dateA.compareTo(dateB);
                                  });
                                
                                // Calculate wins, losses, draws and streak
                                bool streakActive = true;
                                for (var m in sortedMatches.reversed) {
                                  final data = m['data'] as Map<String, dynamic>?;
                                  final isPlayed = data?['played'] == true;
                                  final golesTeamA = (data?['golesTeamA'] as int?) ?? 0;
                                  final golesTeamB = (data?['golesTeamB'] as int?) ?? 0;
                                  
                                  if (isPlayed) {
                                    if (golesTeamA > golesTeamB) {
                                      if (streakActive) currentStreak++;
                                    } else {
                                      streakActive = false;
                                    }
                                  }
                                }
                                
                                // Find next match
                                final now = DateTime.now();
                                for (var m in sortedMatches) {
                                  final data = m['data'] as Map<String, dynamic>?;
                                  final date = (data?['date'] as Timestamp?)?.toDate();
                                  final isPlayed = data?['played'] == true;
                                  
                                  if (date != null && date.isAfter(now) && !isPlayed) {
                                    nextMatchDate = date;
                                    break;
                                  }
                                }
                              }
                              
                              final daysUntilNext = nextMatchDate != null 
                                ? nextMatchDate.difference(DateTime.now()).inDays 
                                : null;
                              
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      // Next match countdown
                                      if (daysUntilNext != null)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [primaryDark.withOpacity(0.95), primary],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primary.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.timer, color: onPrimary, size: 20),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      daysUntilNext == 0 ? '¡Hoy!' : '$daysUntilNext días',
                                                      style: TextStyle(
                                                        color: onPrimary,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Próximo partido',
                                                  style: TextStyle(
                                                    color: onPrimary.withOpacity(0.9),
                                                    fontSize: 11,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (daysUntilNext != null) const SizedBox(width: 8),
                                      // Win streak
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [secondary, secondary.withOpacity(0.75)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: secondary.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.local_fire_department, color: onPrimary, size: 20),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '$currentStreak',
                                                    style: TextStyle(
                                                      color: onPrimary,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currentStreak == 1 ? 'Victoria' : 'Racha',
                                                style: TextStyle(
                                                  color: onPrimary.withOpacity(0.9),
                                                  fontSize: 11,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Player of the month
                                  const SizedBox(height: 12),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('teams')
                                        .doc(teamId)
                                        .collection('players')
                                        .snapshots(),
                                    builder: (context, playersSnapshot) {
                                      if (!playersSnapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      
                                      final players = playersSnapshot.data?.docs ?? [];
                                      if (players.isEmpty) return const SizedBox.shrink();
                                      
                                      // Find player with most goals + assists (excluding coach)
                                      var topPlayer = players.first;
                                      int maxScore = 0;
                                      
                                      for (var player in players) {
                                        final data = player.data() as Map<String, dynamic>?;
                                        final role = data?['role'] as String?;
                                        if (role?.toLowerCase() == 'entrenador') continue;
                                        
                                        final goles = (data?['goles'] as int?) ?? 0;
                                        final asistencias = (data?['asistencias'] as int?) ?? 0;
                                        final score = goles + asistencias;
                                        
                                        if (score > maxScore) {
                                          maxScore = score;
                                          topPlayer = player;
                                        }
                                      }
                                      
                                      if (maxScore == 0) return const SizedBox.shrink();
                                      
                                      final topData = topPlayer.data() as Map<String, dynamic>?;
                                      final topName = topData?['name'] ?? 'Jugador';
                                      final topGoles = (topData?['goles'] as int?) ?? 0;
                                      final topAsistencias = (topData?['asistencias'] as int?) ?? 0;
                                      
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700).withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.star, color: Colors.white, size: 32),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '⭐ Jugador destacado',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    topName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$topGoles goles • $topAsistencias asistencias',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.95),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  // Next match section
                                  const SizedBox(height: 12),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('teams')
                                        .doc(teamId)
                                        .collection('matches')
                                        .where('played', isEqualTo: false)
                                        .orderBy('date', descending: false)
                                        .limit(1)
                                        .snapshots(),
                                    builder: (context, nextMatchSnapshot) {
                                      if (!nextMatchSnapshot.hasData || nextMatchSnapshot.data!.docs.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      
                                      final matchDoc = nextMatchSnapshot.data!.docs.first;
                                      final matchData = matchDoc.data() as Map<String, dynamic>;
                                      final opponent = matchData['rival'] ?? 'Rival';
                                      final matchDate = (matchData['date'] as Timestamp?)?.toDate();
                                      final location = matchData['location'] ?? '';
                                      final dateStr = matchDate != null 
                                          ? '${matchDate.day}/${matchDate.month}/${matchDate.year}'
                                          : 'N/A';
                                      
                                      return Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.primary.withOpacity(0.9), AppColors.primaryDark],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'next_match'.tr(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.sports_soccer, color: Colors.white70, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    opponent,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.schedule, color: Colors.white70, size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (location.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      location,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatCard(
                                icon: Icons.sports_soccer,
                                label: "Partidos",
                                value: (statsData["partidos"] ?? 0)
                                    .toString(),
                                color: Colors.blue,
                              ),
                              _StatCard(
                                icon: Icons.sports,
                                label: "Goles",
                                value: (statsData["goles"] ?? 0).toString(),
                                color: Colors.green,
                              ),
                              _StatCard(
                                icon: Icons.group,
                                label: "Asistencias",
                                value: (statsData["asistencias"] ?? 0)
                                    .toString(),
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        if (role == "jugador")
                          Column(
                            children: [
                              const SizedBox(height: 12),

                              // Mostrar promedios de equipo (excluyendo entrenador) y estadísticas propias
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('teams')
                                    .doc(teamId)
                                    .collection('players')
                                    .snapshots(),
                                builder: (context, teamSnapshot) {
                                  if (teamSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final docs = teamSnapshot.data?.docs ?? [];
                                  if (docs.isEmpty) {
                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text('Promedios', style: TextStyle(fontWeight: FontWeight.bold)),
                                            SizedBox(height: 8),
                                            Text('No hay datos de jugadores en el equipo aún.'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  int totalG = 0, totalA = 0, totalM = 0, count = 0;
                                  for (var d in docs) {
                                    final pd = d.data() as Map<String, dynamic>;
                                    final r = (pd['role'] as String?) ?? '';
                                    if (r.toLowerCase() == 'entrenador') continue;
                                    totalG += (pd['goles'] as int?) ?? 0;
                                    totalA += (pd['asistencias'] as int?) ?? 0;
                                    totalM += (pd['minutos'] as int?) ?? 0;
                                    count++;
                                  }

                                  final teamGProm = count > 0 ? (totalG / count) : 0.0;
                                  final teamAProm = count > 0 ? (totalA / count) : 0.0;
                                  final teamMProm = count > 0 ? (totalM / count) : 0.0;

                                  final myG = (statsData['goles'] ?? 0) as int;
                                  final myA = (statsData['asistencias'] ?? 0) as int;
                                  final myM = (statsData['minutos'] ?? 0) as int;
                                  
                                  final myGoalsPerMin = myM > 0 ? (myG / myM * 90).toStringAsFixed(2) : '0.00';
                                  final myAssistsPerMin = myM > 0 ? (myA / myM * 90).toStringAsFixed(2) : '0.00';

                                  return Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Promedios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('📊 Promedio equipo', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.sports, size: 20, color: Colors.blue),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Goles / Jug', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 26,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text(teamGProm.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.group, size: 20, color: Colors.orange),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Asist / Jug', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 26,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text(teamAProm.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.access_time, size: 20, color: Colors.green),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Min / Jug', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 26,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text(teamMProm.toStringAsFixed(0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(colors: [Colors.amber[50]!, Colors.amber[100]!]),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('⭐ Tus estadísticas', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.sports_soccer, size: 18, color: Colors.blue),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Goles', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 24,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text('$myG', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.group, size: 18, color: Colors.orange),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Asistencias', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 24,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text('$myA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.access_time, size: 18, color: Colors.green),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Minutos', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 24,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text('$myM', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Goles/90', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 22,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text(myGoalsPerMin, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('Asist/90', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                const SizedBox(height: 4),
                                                                SizedBox(
                                                                  height: 22,
                                                                  child: FittedBox(
                                                                    fit: BoxFit.scaleDown,
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Text(myAssistsPerMin, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),

                role == "entrenador"
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: context.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.admin_panel_settings, color: onPrimary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Gestión del equipo",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _managementButton(
                                context,
                                icon: Icons.group,
                                label: "Ver jugadores",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayersPage(teamId: teamId),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _managementButton(
                                context,
                                icon: Icons.sports_soccer,
                                label: "Partidos",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MatchesPage(teamId: teamId),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _managementButton(
                                context,
                                icon: Icons.person_add,
                                label: "Invitar",
                                gradient: _secondaryButtonGradient(context),
                                shadowColor: context.secondaryColor.withOpacity(0.25),
                                onPressed: () => _showInviteDialog(context, teamId),
                              ),
                              const SizedBox(height: 8),
                              _managementButton(
                                context,
                                icon: Icons.fitness_center,
                                label: "Entrenamientos",
                                gradient: _secondaryButtonGradient(context),
                                shadowColor: context.secondaryColor.withOpacity(0.25),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => TrainingsPage(teamId: teamId)),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _managementButton(
                                context,
                                icon: Icons.calendar_month,
                                label: "Calendario",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CalendarPage(teamId: teamId),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _managementButton(
                                context,
                                icon: Icons.bar_chart,
                                label: "Estadísticas",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamStatsPage(teamId: teamId),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: context.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.sports_soccer, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Próximos partidos",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('teams')
                                .doc(teamId)
                                .collection('matches')
                                .where('played', isEqualTo: false)
                                .orderBy('date', descending: false)
                                .limit(1)
                                .snapshots(),
                            builder: (context, nextMatchSnapshot) {
                              if (!nextMatchSnapshot.hasData || nextMatchSnapshot.data!.docs.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              final matchDoc = nextMatchSnapshot.data!.docs.first;
                              final matchData = matchDoc.data() as Map<String, dynamic>;
                              final opponent = matchData['rival'] ?? 'Rival';
                              final matchDate = (matchData['date'] as Timestamp?)?.toDate();
                              final location = matchData['location'] ?? '';
                              final dateStr = matchDate != null 
                                  ? '${matchDate.day}/${matchDate.month}/${matchDate.year}'
                                  : 'N/A';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryDark.withOpacity(0.95), primary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Próximo Partido',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.sports_soccer, color: Colors.white70, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            opponent,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.white70, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (location.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              location,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("teams")
                                .doc(teamId)
                                .collection("matches")
                                .orderBy("date", descending: false)
                                .snapshots(),
                            builder: (context, matchSnapshot) {
                              if (!matchSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final matches = matchSnapshot.data!.docs;

                              if (matches.isEmpty) {
                                return const Text(
                                  "No hay partidos programados todavía ⚽",
                                );
                              }

                              return Column(
                                children: matches.map((matchDoc) {
                                  final matchData =
                                      matchDoc.data() as Map<String, dynamic>;
                                  final teamA =
                                      matchData["teamA"] ?? "Desconocido";
                                  final teamB =
                                      matchData["teamB"] ?? "Desconocido";
                                  final date = (matchData["date"] as Timestamp)
                                      .toDate();
                                  final matchId = matchDoc.id;
                                  final convocados = List<String>.from(matchData['convocados'] ?? []);
                                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                  final isConvocado = currentUserId != null && convocados.contains(currentUserId);

                                  final formattedDate =
                                      "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () async {
                                        // Determinar si es coach
                                        bool isCoach = false;
                                        if (currentUserId != null) {
                                          try {
                                            final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
                                            final coachId = teamDoc.data()?['coachId'] as String?;
                                            isCoach = (coachId == currentUserId);
                                          } catch (_) {}
                                        }
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MatchAvailabilityPage(
                                                teamId: teamId!,
                                                matchId: matchId,
                                                isCoach: isCoach,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.sports_soccer, color: Theme.of(context).primaryColor, size: 40),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "$teamA vs $teamB",
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (matchData['played'] == true)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.emoji_events, size: 14, color: Colors.blue),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${matchData['golesTeamA'] ?? 0} - ${matchData['golesTeamB'] ?? 0}',
                                                            style: const TextStyle(
                                                              color: Colors.blue,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (isConvocado && matchData['played'] != true)
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                                        const SizedBox(width: 4),
                                                        const Text('Convocado', style: TextStyle(color: Colors.green, fontSize: 12)),
                                                      ],
                                                    ),
                                                  StreamBuilder<DocumentSnapshot>(
                                                    stream: FirebaseFirestore.instance
                                                        .collection('teams')
                                                        .doc(teamId)
                                                        .collection('matches')
                                                        .doc(matchId)
                                                        .collection('availability')
                                                        .doc(currentUserId)
                                                        .snapshots(),
                                                    builder: (context, availSnap) {
                                                      final availData = availSnap.data?.data() as Map<String, dynamic>?;
                                                      final status = availData?['status'] as String?;
                                                      if (status == null) {
                                                        return Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.help_outline, size: 14, color: Colors.orange),
                                                            const SizedBox(width: 4),
                                                            const Flexible(
                                                              child: Text(
                                                                '¿Vienes? Indica disponibilidad',
                                                                style: TextStyle(color: Colors.orange, fontSize: 12),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
              ],
            ),
          ),
          bottomNavigationBar: role == "jugador"
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            context,
                            icon: Icons.home,
                            label: 'Inicio',
                            color: primary,
                            onTap: () {},
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.calendar_month,
                            label: 'Calendario',
                            color: secondary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CalendarPage(teamId: teamId),
                                ),
                              );
                            },
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.sports_soccer,
                            label: 'Partidos',
                            color: primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchesPage(teamId: teamId),
                                ),
                              );
                            },
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.bar_chart,
                            label: 'Stats',
                            color: secondary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullStatsPage(
                                    teamId: teamId,
                                    playerId: FirebaseAuth.instance.currentUser!.uid,
                                    playerName: userData["name"] ?? "Jugador",
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextMatchCard extends StatefulWidget {
  final String teamId;

  const _NextMatchCard({required this.teamId});

  @override
  State<_NextMatchCard> createState() => __NextMatchCardState();
}

class __NextMatchCardState extends State<_NextMatchCard> {
  bool _isVisible = true;

  void _hideCard() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('matches')
            .where('played', isEqualTo: false)
            .snapshots(),
        builder: (context, nextMatchSnapshot) {

          // Mostrar placeholder mientras carga
          if (!nextMatchSnapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'PRÓXIMO PARTIDO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _hideCard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ],
            );
          }

          // Si no hay partidos pendientes
          if (nextMatchSnapshot.data!.docs.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'PRÓXIMO PARTIDO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _hideCard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'No hay partidos programados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }

          // Ordenar los documentos por fecha
          final docs = nextMatchSnapshot.data!.docs;
          docs.sort((a, b) {
            final dateA = (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateB = (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            return dateA.compareTo(dateB);
          });

          final matchDoc = docs.first;
          final matchData = matchDoc.data() as Map<String, dynamic>;
          final opponentTeam = matchData['rival'] ?? 'Equipo contrario';
          final matchDate = (matchData['date'] as Timestamp?)?.toDate();
          final location = matchData['location'] ?? '';
          final dateStr = matchDate != null 
              ? '${matchDate.day}/${matchDate.month}/${matchDate.year}'
              : 'N/A';
          final timeStr = matchDate != null
              ? '${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}'
              : '';

          // Obtener el nombre del equipo actual del Firebase
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('teams')
                .doc(widget.teamId)
                .get(),
            builder: (context, teamSnapshot) {
              final teamName = (teamSnapshot.data?.data() as Map<String, dynamic>?)?['name'] ?? 'Tu equipo';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRÓXIMO PARTIDO',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    teamName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'vs',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    opponentTeam,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: _hideCard,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FECHA',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, color: Colors.white70, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HORA',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UBICACIÓN',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
              );
            },
          );
        },
      ),
    );
  }
}
