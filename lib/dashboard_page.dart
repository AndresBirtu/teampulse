import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:teampulse/home_page.dart';
import 'match_page.dart';
import 'players_page.dart';
import 'full_stats_page.dart';
import 'team_stats_page.dart';
import 'trainings_page.dart';
import 'player_profile_page.dart';
import 'match_availability_page.dart';
import 'calendar_page.dart';
import 'theme/app_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  void _showMatchStatsDialog(BuildContext context, String title, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text('Total: $count partidos'),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar'))],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              final playerId = uid;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Mi perfil"),
                  content: const Text("¿Deseas ver tu perfil y editar tu foto?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final teamId = await FirebaseFirestore.instance.collection('users').doc(playerId).get().then((doc) => doc['teamId']);
                        if (teamId != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerProfilePage(teamId: teamId, playerId: playerId),
                            ),
                          );
                        }
                      },
                      child: const Text("Ver perfil"),
                    ),
                  ],
                ),
              );
            },
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

          return Scaffold(
            backgroundColor: AppColors.background,
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
                              int played = 0, won = 0, lost = 0;
                              int currentStreak = 0;
                              DateTime? nextMatchDate;
                              
                              if (matchSnapshot.hasData) {
                                final matches = matchSnapshot.data?.docs ?? [];
                                played = matches.length;
                                
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
                                      won++;
                                      if (streakActive) currentStreak++;
                                    } else if (golesTeamA < golesTeamB) {
                                      lost++;
                                      streakActive = false;
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
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showMatchStatsDialog(context, 'Partidos Jugados', played),
                                          child: _StatCard(
                                            icon: Icons.sports_soccer,
                                            label: "Jugados",
                                            value: played.toString(),
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showMatchStatsDialog(context, 'Partidos Ganados', won),
                                          child: _StatCard(
                                            icon: Icons.emoji_events,
                                            label: "Ganados",
                                            value: won.toString(),
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showMatchStatsDialog(context, 'Partidos Perdidos', lost),
                                          child: _StatCard(
                                            icon: Icons.cancel,
                                            label: "Perdidos",
                                            value: lost.toString(),
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // New widgets row
                                  Row(
                                    children: [
                                      // Next match countdown
                                      if (daysUntilNext != null)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [AppColors.primary.withOpacity(0.8), AppColors.primaryDark],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.3),
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
                                                    const Icon(Icons.timer, color: Colors.white, size: 20),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      daysUntilNext == 0 ? '¡Hoy!' : '$daysUntilNext días',
                                                      style: const TextStyle(
                                                        color: Colors.white,
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
                                                    color: Colors.white.withOpacity(0.9),
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
                                              colors: [AppColors.secondary.withOpacity(0.8), const Color(0xFF388E3C)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.secondary.withOpacity(0.3),
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
                                                  const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '$currentStreak',
                                                    style: const TextStyle(
                                                      color: Colors.white,
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
                                                  color: Colors.white.withOpacity(0.9),
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
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Gestión del equipo",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
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
                                      icon: const Icon(Icons.group, color: Colors.white, size: 24),
                                      label: const Text(
                                        "Ver jugadores",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PlayersPage(teamId: teamId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
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
                                      icon: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                                      label: const Text(
                                        "Partidos",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MatchesPage(teamId: teamId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.trainingGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(0.3),
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
                                      icon: const Icon(Icons.person_add, color: Colors.white, size: 24),
                                      label: const Text(
                                        "Invitar",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () {
                                        _showInviteDialog(context, teamId);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.trainingGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.trainingColor.withOpacity(0.3),
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
                                      icon: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                                      label: const Text(
                                        "Entrenamientos",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => TrainingsPage(teamId: teamId)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
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
                                      icon: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
                                      label: const Text(
                                        "Calendario",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CalendarPage(teamId: teamId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
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
                                      icon: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
                                      label: const Text(
                                        "Estadísticas",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TeamStatsPage(teamId: teamId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                  gradient: AppColors.matchGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.sports_soccer, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Próximos partidos",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
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
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.emoji_events, size: 14, color: Colors.blue),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            'Resultado: ${matchData['golesTeamA'] ?? 0} - ${matchData['golesTeamB'] ?? 0}',
                                                            style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
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
                            color: AppColors.primary,
                            onTap: () {},
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.calendar_month,
                            label: 'Calendario',
                            color: AppColors.secondary,
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
                            color: AppColors.primary,
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
                            color: AppColors.accent,
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
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
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
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.surface, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
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
