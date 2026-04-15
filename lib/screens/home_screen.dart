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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Card Header ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          game.locationName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 14, color: Colors.white54),
                                            const SizedBox(width: 4),
                                            Text(dateString, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Player count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.group, size: 14, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${game.players.length}/${game.maxPlayers}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Roster Chips ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ROSTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white38, letterSpacing: 1.2)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: game.players.map((uid) {
                                      final profile = game.playerProfiles[uid] ?? {};
                                      final playerName = profile['name'] ?? 'Unknown Player';
                                      final photoUrl = profile['photoUrl'] ?? '';
                                      final isMe = uid == user?.uid;
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
                                        onDeleted: showRemove ? () => FirestoreService().leaveGame(game.id, uid) : null,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            // ── Action Footer ──────────────────────────────
                            const Divider(height: 1, color: Colors.white10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Share button
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        final String baseUrl = kIsWeb ? Uri.base.origin : 'https://nextdink-11.web.app';
                                        final inviteLink = '$baseUrl/join?gameId=${game.id}';
                                        Share.share('Dink with me! Join my Pickleball game at ${game.locationName}\n\nTap here to accept: $inviteLink');
                                      },
                                      icon: Icon(Icons.ios_share_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                                      label: Text(
                                        'Share Invite',
                                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),

                                  // Vertical divider between buttons
                                  if (isOrganizer)
                                    Container(width: 1, height: 32, color: Colors.white10),

                                  // Cancel Game — organizer only
                                  if (isOrganizer)
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF1E1E1E),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: const Row(
                                                children: [
                                                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                                                  SizedBox(width: 8),
                                                  Text('Cancel Game?', style: TextStyle(color: Colors.white, fontSize: 18)),
                                                ],
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    game.locationName,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(dateString, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'This will permanently remove the game for all players. This cannot be undone.',
                                                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Keep Game', style: TextStyle(color: Colors.white54)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.redAccent,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  child: const Text('Yes, Cancel It', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            FirestoreService().deleteGame(game.id);
                                          }
                                        },
                                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                                        label: const Text(
                                          'Cancel Game',
                                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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
