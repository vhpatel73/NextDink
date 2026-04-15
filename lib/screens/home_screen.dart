import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/game.dart';
import 'wizard_screen.dart';
import '../widgets/app_footer.dart';
import 'admin_logs_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final month = DateFormat('MMM').format(dt);     // Apr
  final day   = _ordinal(dt.day);                 // 15th
  final time  = DateFormat('h:mma').format(dt);   // 7:58AM
  return '$month $day @ $time';
}


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
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF050501),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(height: 10),
                    Text(user?.displayName ?? 'Player', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Color(0xFFD4F82B)),
                title: const Text('My Dashboard'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.orange),
                title: const Text('Admin Audit Logs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminAuditLogsScreen()),
                  );
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout'),
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
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
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: const AssetImage('assets/swing.png'),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  colorFilter: ColorFilter.mode(
                                    const Color(0xFF010101).withOpacity(0.2), 
                                    BlendMode.dstATop,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height - 200, 
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(height: 100), // Push text down
                                Text(
                                  'No games scheduled yet.',
                                  style: TextStyle(color: Colors.white54, fontSize: 16),
                                ),
                                AppFooter(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: games.length + 1, // Add 1 for the footer
                    itemBuilder: (context, index) {
                      if (index == games.length) {
                        return const AppFooter();
                      }

                      final game = games[index];
                      final dateString = _formatGameTime(game.scheduledTime);
                      
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
                                        Builder(builder: (_) {
                                          final parts = game.locationName.split(',');
                                          final mainName = parts[0].trim();
                                          final address = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;
                                          
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mainName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                              ),
                                              if (address != null && address.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  address,
                                                  style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w400),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          );
                                        }),
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
                                  // Status + player count badges
                                  Row(
                                    children: [
                                      // Status badge
                                      Builder(builder: (_) {
                                        final isInProgress = game.status == GameStatus.inProgress;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isInProgress
                                                ? Colors.orangeAccent.withOpacity(0.15)
                                                : Colors.green.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isInProgress
                                                  ? Colors.orangeAccent.withOpacity(0.5)
                                                  : Colors.green.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isInProgress ? Colors.orangeAccent : Colors.green,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                game.statusLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isInProgress ? Colors.orangeAccent : Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(width: 8),
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
                                        onDeleted: showRemove
                                            ? () {
                                                showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    backgroundColor: const Color(0xFF1E1E1E),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: Row(
                                                      children: [
                                                        Icon(
                                                          isMe ? Icons.exit_to_app : Icons.person_remove,
                                                          color: Colors.orangeAccent,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          isMe ? 'Leave Game?' : 'Remove Player?',
                                                          style: const TextStyle(color: Colors.white, fontSize: 18),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      isMe
                                                          ? 'Are you sure you want to leave this game?\nYou can rejoin later if there is space.'
                                                          : 'Remove $playerName from the roster?\nThey will need a new invite link to rejoin.',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx, false),
                                                        child: const Text('Keep', style: TextStyle(color: Colors.white54)),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.orangeAccent,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        child: Text(
                                                          isMe ? 'Yes, Leave' : 'Yes, Remove',
                                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ).then((confirmed) {
                                                  if (confirmed == true) {
                                                    FirestoreService().leaveGame(game.id, uid);
                                                  }
                                                });
                                              }
                                            : null,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            // ── Action Footer ──────────────────────────────
                            // only render footer when at least one action is available
                            Builder(builder: (_) {
                              final canShare  = game.status != GameStatus.completed;
                              final canCancel = isOrganizer && game.status == GameStatus.scheduled;
                              if (!canShare && !canCancel) return const SizedBox.shrink();
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Divider(height: 1, color: Colors.white10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        // Share Invite — Scheduled + In-Progress only
                                        if (canShare)
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

                                        // Divider between buttons
                                        if (canShare && canCancel)
                                          Container(width: 1, height: 32, color: Colors.white10),

                                        // Cancel Game — Scheduled + organizer only
                                        if (canCancel)
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
                                                          'The game will be marked as Cancelled. The record is kept for history but removed from all players\' dashboards.',
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
                                                  FirestoreService().cancelGame(game.id);
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
                              );
                            }),
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
