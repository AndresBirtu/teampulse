import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:teampulse/features/matches/presentation/pages/matches_page.dart'
    as match;
import 'package:teampulse/features/trainings/presentation/pages/trainings_page.dart';
import 'package:teampulse/theme/app_themes.dart';

class CalendarPage extends StatefulWidget {
  final String teamId;

  const CalendarPage({required this.teamId, super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Rango de fechas: 3 meses atrás y 6 meses adelante
      final start = DateTime.now().subtract(const Duration(days: 90));
      final end = DateTime.now().add(const Duration(days: 180));

      // Cargar partidos
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('matches')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      // Cargar entrenamientos
      final trainingsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('trainings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      // Procesar partidos
      for (final doc in matchesSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dayKey = DateTime(date.year, date.month, date.day);

        events[dayKey] = events[dayKey] ?? [];
        events[dayKey]!.add({
          'id': doc.id,
          'type': 'match',
          'title': '${data['teamA']} vs ${data['teamB']}',
          'time': DateFormat('HH:mm').format(date),
          'date': date,
          'played': data['played'] ?? false,
        });
      }

      // Procesar entrenamientos
      for (final doc in trainingsSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dayKey = DateTime(date.year, date.month, date.day);

        events[dayKey] = events[dayKey] ?? [];
        events[dayKey]!.add({
          'id': doc.id,
          'type': 'training',
          'title': data['title'] ?? 'Entrenamiento',
          'time': DateFormat('HH:mm').format(date),
          'date': date,
          'location': data['location'],
        });
      }

      // Ordenar eventos por hora
      events.forEach((key, value) {
        value.sort((a, b) => a['date'].compareTo(b['date']));
      });

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando eventos: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;
    final onPrimary = colorScheme.onPrimary;
    final textSecondary = theme.textTheme.bodySmall?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Recargar eventos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 3,
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ) ??
                          TextStyle(color: primary, fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(Icons.chevron_left, color: primary),
                      rightChevronIcon: Icon(Icons.chevron_right, color: primary),
                      formatButtonDecoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle:
                          TextStyle(color: onPrimary, fontWeight: FontWeight.w600),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: secondary.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: secondary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      weekendTextStyle: TextStyle(color: textSecondary),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() => _calendarFormat = format);
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildEventsList()),
              ],
            ),
    );
  }

  Widget _buildEventsList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;
    final onPrimary = colorScheme.onPrimary;
    final textSecondary = theme.textTheme.bodySmall?.color ?? Colors.black54;
    final successColor = Colors.green.shade600;

    if (_selectedDay == null) {
      return const Center(
        child: Text('Selecciona un día para ver eventos'),
      );
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay eventos para este día',
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isMatch = event['type'] == 'match';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isMatch
                    ? context.primaryGradient
                    : LinearGradient(
                        colors: [secondary, secondary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isMatch ? primary : secondary).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isMatch ? Icons.sports_soccer : Icons.fitness_center,
                color: onPrimary,
                size: 24,
              ),
            ),
            title: Text(
              event['title'],
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(event['time'], style: theme.textTheme.bodySmall),
                  ],
                ),
                if (isMatch && event['played'] == true)
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: successColor),
                      const SizedBox(width: 4),
                      Text(
                        'Jugado',
                        style: TextStyle(color: successColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                if (!isMatch && event['location'] != null)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(event['location'], style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: primary,
            ),
            onTap: () {
              if (isMatch) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => match.MatchesPage(teamId: widget.teamId),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingsPage(teamId: widget.teamId),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
