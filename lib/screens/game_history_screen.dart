import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class GameHistoryScreen extends StatelessWidget {
  const GameHistoryScreen({super.key});

  /// Returns the ordinal suffix for a day number (1→"st", 2→"nd", 3→"rd", 4+→"th")
  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  /// Formats a DateTime as "Apr 15th @ 7:58AM"
  String _formatGameTime(DateTime dt) {
    final month = DateFormat('MMM').format(dt);
    final day   = _ordinal(dt.day);
    final time  = DateFormat('h:mma').format(dt);
    return '$month $day @ $time';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Match History',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Game>>(
        stream: FirestoreService().getUserGameHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No past matches found.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final games = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final isOrganizer = game.organizerId == currentUserId;

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.locationName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isOrganizer)
                        _roleChip('Organizer', Colors.purpleAccent)
                      else
                        _roleChip('Player', Colors.white38),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        _formatGameTime(game.scheduledTime),
                        style: const TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusChip(game.statusLabel, _getStatusColor(game.status)),
                          const SizedBox(width: 8),
                          Text(
                            '${game.players.length}/${game.maxPlayers} players',
                            style: const TextStyle(color: Colors.white24, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _roleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.scheduled: return const Color(0xFFD4F82B);
      case GameStatus.inProgress: return Colors.orange;
      case GameStatus.completed: return Colors.blue;
      case GameStatus.cancelled: return Colors.redAccent;
    }
  }
}
