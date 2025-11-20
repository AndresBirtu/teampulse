import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_player_page.dart';

class PlayersPage extends StatefulWidget {
  final String teamId;

  const PlayersPage({super.key, required this.teamId});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  String _sortBy = 'name'; // 'name', 'name-desc', 'position'
  String _filterPosition = ''; // '' = no filter

  @override
  Widget build(BuildContext context) {
    final playersStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('players')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jugadores del equipo"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: playersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var players = snapshot.data!.docs;

          // Filtrar por posición si hay filtro activo
          if (_filterPosition.isNotEmpty) {
            players = players.where((p) => (p.data() as Map<String, dynamic>)['posicion'] == _filterPosition).toList();
          }

          // Ordenar según el criterio seleccionado
          players.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aName = aData['name'] ?? '';
            final aPos = aData['posicion'] ?? '';
            final bName = bData['name'] ?? '';
            final bPos = bData['posicion'] ?? '';

            switch (_sortBy) {
              case 'name':
                return aName.compareTo(bName); // A-Z
              case 'name-desc':
                return bName.compareTo(aName); // Z-A
              case 'position':
                return aPos.compareTo(bPos); // Por posición
              default:
                return 0;
            }
          });

          if (players.isEmpty) {
            return const Center(child: Text("No hay jugadores en el equipo"));
          }

          return Column(
            children: [
              // Controles de filtro y orden
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _sortBy,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('A → Z')),
                          DropdownMenuItem(value: 'name-desc', child: Text('Z → A')),
                          DropdownMenuItem(value: 'position', child: Text('Por posición')),
                        ],
                        onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Filtrar por posición:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _filterPosition,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Todas las posiciones')),
                          ...['Portero', 'Defensa', 'Centrocampista', 'Delantero', 'Lateral', 'Delantero Centro']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                        ],
                        onChanged: (value) => setState(() => _filterPosition = value ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final playerData = player.data() as Map<String, dynamic>;
                    final name = playerData['name'] ?? 'Jugador sin nombre';
                    final photoUrl = playerData['photoUrl'] ?? '';
                    final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty
                              ? Text(initials.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          "Posición: ${playerData['posicion'] ?? '-'} · Partidos: ${playerData['partidos'] ?? 0}\nGoles: ${playerData['goles'] ?? 0} · Asist: ${playerData['asistencias'] ?? 0}",
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        isThreeLine: true,
                        trailing: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPlayerPage(
                                  teamId: widget.teamId,
                                  playerId: player.id,
                                  playerData: playerData,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                            child: Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}