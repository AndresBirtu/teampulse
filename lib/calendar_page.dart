import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'match_page.dart' as match;
import 'trainings_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
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
                    // locale: 'es_ES', // Comentado por ahora, requiere configuración adicional
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: const TextStyle(color: Colors.white),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
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
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isMatch ? Colors.red[700] : Colors.green[700],
              child: Icon(
                isMatch ? Icons.sports_soccer : Icons.fitness_center,
                color: Colors.white,
              ),
            ),
            title: Text(
              event['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text(event['time']),
                  ],
                ),
                if (isMatch && event['played'] == true)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Jugado', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                if (!isMatch && event['location'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Text(event['location']),
                    ],
                  ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () {
              if (isMatch) {
                // Navegar a la lista de partidos
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => match.MatchesPage(teamId: widget.teamId),
                  ),
                );
              } else {
                // Navegar a entrenamientos
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
