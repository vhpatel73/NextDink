import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/game.dart';
import 'wizard_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';


// Returns up to 2 uppercase initials from a name or email string
String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'[\s@._]+'));
  if (parts.length >= 2 && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'P';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'NextDink', 
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w900, 
                letterSpacing: -1.0,
                color: Theme.of(context).colorScheme.primary,
              )
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
            tooltip: 'Sign Out',
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                  ? Text(
                      _getInitials(user?.displayName ?? user?.email ?? 'P'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? 'Player'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Game>>(
                stream: FirestoreService().getUserGames(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final games = snapshot.data ?? [];

                  if (games.isEmpty) {
                    return const Center(
                      child: Text(
                        'No games scheduled yet.',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      // Format simple date
                      // We can add intl package later for better formatting
                      final dateData = game.scheduledTime;
                      final dateString = "${dateData.month}/${dateData.day} @ ${dateData.hour}:${dateData.minute.toString().padLeft(2, '0')}";
                      
                      final isOrganizer = game.players.isNotEmpty && game.players.first == user?.uid;
                      
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(game.locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text('Time: $dateString', style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text('${game.players.length}/${game.maxPlayers}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.ios_share, color: Color(0xFFD4F82B)),
                                        onPressed: () {
                                          final String baseUrl = kIsWeb ? Uri.base.origin : 'https://nextdink-11.web.app';
                                          final inviteLink = '$baseUrl/join?gameId=${game.id}';
                                          Share.share('Dink with me! Join my Pickleball game at ${game.locationName}\n\nTap here to accept: $inviteLink');
                                        },
                                      ),
                                      if (isOrganizer)
                                        IconButton(
                                          padding: const EdgeInsets.only(left: 8),
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                          tooltip: 'Cancel Game',
                                          onPressed: () => FirestoreService().deleteGame(game.id),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Roster:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: game.players.map((uid) {
                                  final profile = game.playerProfiles[uid] ?? {};
                                  final playerName = profile['name'] ?? 'Unknown Player';
                                  final photoUrl = profile['photoUrl'] ?? '';
                                  final isMe = uid == user?.uid;
                                  
                                  // I can leave if I am NOT the organizer (organizers must outright cancel the game)
                                  // I can kick someone if I AM the organizer
                                  final showRemove = (isMe && !isOrganizer) || (isOrganizer && !isMe);

                                  return Chip(
                                    avatar: CircleAvatar(
                                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                      backgroundColor: Colors.grey.shade800,
                                      child: photoUrl.isEmpty ? Text(playerName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)) : null,
                                    ),
                                    label: Text(playerName),
                                    backgroundColor: Colors.black26,
                                    labelStyle: const TextStyle(color: Colors.white),
                                    deleteIcon: showRemove ? const Icon(Icons.close, size: 16) : null,
                                    onDeleted: showRemove
                                        ? () => FirestoreService().leaveGame(game.id, uid)
                                        : null,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGameWizardScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('New Game', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
