import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'theme/app_themes.dart';

class FullStatsPage extends StatefulWidget {
  final String teamId;
  final String playerId;
  final String playerName;

  const FullStatsPage({
    super.key,
    required this.teamId,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<FullStatsPage> createState() => _FullStatsPageState();
}

class _FullStatsPageState extends State<FullStatsPage> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _secondaryColor => Theme.of(context).colorScheme.secondary;
  Color get _surfaceColor => Theme.of(context).colorScheme.surface;
  Color get _backgroundColor => Theme.of(context).colorScheme.background;
  Color get _textPrimaryColor => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
  Color get _textSecondaryColor => Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
  Color get _tertiaryColor => Theme.of(context).colorScheme.tertiary ?? Theme.of(context).colorScheme.secondary;
  Color get _errorColor => Theme.of(context).colorScheme.error;
  LinearGradient get _primaryGradient => context.primaryGradient;

  @override
  Widget build(BuildContext context) {
    final playerStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('players')
        .doc(widget.playerId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas: ${widget.playerName}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _primaryGradient,
          ),
        ),
        elevation: 0,
      ),
      backgroundColor: _backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: playerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final playerData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getMatchHistory(),
            builder: (context, historySnapshot) {
              if (!historySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final matchHistory = historySnapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player header card
                    Container(
                      decoration: BoxDecoration(
                        gradient: _primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.playerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${playerData['partidos'] ?? 0} partidos jugados',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats summary grid
                    _buildStatsGrid(playerData),
                    const SizedBox(height: 24),

                    // Evolution charts
                    if (matchHistory.length >= 2) ...[
                      _buildSectionTitle('Evolución', Icons.trending_up),
                      const SizedBox(height: 16),
                      _buildGoalsEvolutionChart(matchHistory),
                      const SizedBox(height: 20),
                      _buildAssistsEvolutionChart(matchHistory),
                      const SizedBox(height: 24),
                    ],

                    // Match history
                    _buildSectionTitle('Historial de partidos', Icons.history),
                    const SizedBox(height: 16),
                    _buildMatchHistory(matchHistory),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: _primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> playerData) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Goles',
          playerData['goles']?.toString() ?? '0',
          Icons.sports_soccer,
          _primaryColor,
        ),
        _buildStatCard(
          'Asistencias',
          playerData['asistencias']?.toString() ?? '0',
          Icons.emoji_events,
          _secondaryColor,
        ),
        _buildStatCard(
          'Minutos',
          playerData['minutos']?.toString() ?? '0',
          Icons.timer,
          _tertiaryColor,
        ),
        _buildStatCard(
          'Tarjetas',
          '${playerData['tarjetas_amarillas'] ?? 0}/${playerData['tarjetas_rojas'] ?? 0}',
          Icons.credit_card,
          _errorColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsEvolutionChart(List<Map<String, dynamic>> matchHistory) {
    // Show goals per match to display variation
    final spots = <FlSpot>[];
    
    for (int i = 0; i < matchHistory.length; i++) {
      final goles = (matchHistory[i]['goles'] as int?) ?? 0;
      spots.add(FlSpot(i.toDouble(), goles.toDouble()));
    }

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_soccer, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Goles por partido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 12, color: _textSecondaryColor),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < matchHistory.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'P${value.toInt() + 1}',
                              style: TextStyle(fontSize: 10, color: _textSecondaryColor),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _primaryColor.withOpacity(0.3),
                          _primaryColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistsEvolutionChart(List<Map<String, dynamic>> matchHistory) {
    // Show assists per match to display variation
    final spots = <FlSpot>[];
    
    for (int i = 0; i < matchHistory.length; i++) {
      final asistencias = (matchHistory[i]['asistencias'] as int?) ?? 0;
      spots.add(FlSpot(i.toDouble(), asistencias.toDouble()));
    }

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _secondaryColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: _secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Asistencias por partido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 12, color: _textSecondaryColor),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < matchHistory.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'P${value.toInt() + 1}',
                              style: TextStyle(fontSize: 10, color: _textSecondaryColor),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _secondaryColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _secondaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _secondaryColor.withOpacity(0.3),
                          _secondaryColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistory(List<Map<String, dynamic>> matchHistory) {
    if (matchHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.sports_soccer, size: 48, color: _textSecondaryColor),
              const SizedBox(height: 12),
              Text(
                'No hay partidos registrados',
                style: TextStyle(color: _textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: matchHistory.map((match) {
        final date = (match['date'] as Timestamp?)?.toDate();
        final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Sin fecha';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                match['titular'] == true ? Icons.star : Icons.person,
                color: _primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              match['opponent'] ?? 'Partido',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimaryColor),
            ),
            subtitle: Text(dateStr, style: TextStyle(fontSize: 12, color: _textSecondaryColor)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${match['goles'] ?? 0}G / ${match['asistencias'] ?? 0}A',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _getMatchHistory() async {
    try {
      // Get all matches
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .orderBy('date', descending: false)
          .get();

      final List<Map<String, dynamic>> history = [];

      for (final matchDoc in matchesSnapshot.docs) {
        // Get player stats for this match
        final statsDoc = await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('matches')
            .doc(matchDoc.id)
            .collection('stats')
            .doc(widget.playerId)
            .get();

        if (statsDoc.exists) {
          final statsData = statsDoc.data() ?? {};
          final matchData = matchDoc.data();
          
          history.add({
            'matchId': matchDoc.id,
            'date': matchData['date'],
            'opponent': matchData['opponent'] ?? 'Partido',
            'goles': statsData['goles'] ?? 0,
            'asistencias': statsData['asistencias'] ?? 0,
            'minutos': statsData['minutos'] ?? 0,
            'titular': statsData['titular'] ?? false,
          });
        }
      }

      return history;
    } catch (e) {
      return [];
    }
  }
}
