import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;
  final GlobalKey<NavigatorState> navigatorKey;
  
  String? _pendingGameId;

  DeepLinkService(this.navigatorKey) {
    _appLinks = AppLinks();
    _initDeepLinks();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && _pendingGameId != null) {
        // User just logged in and has a pending game!
        final gameIdToJoin = _pendingGameId!;
        _pendingGameId = null; // Clear it immediately
        _processJoinGame(gameIdToJoin);
      }
    });
  }

  void _initDeepLinks() async {
    // Check initial link if app was closed
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to parse initial deep link: $e");
    }

    // Subscribe to links when app is in background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.contains('join') || uri.host == 'join') {
      final gameId = uri.queryParameters['gameId'];
      if (gameId != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // Tell the user to log in first, but save the gameId
          _pendingGameId = gameId;
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(content: Text('Please log in to join the game!')),
            );
          }
        } else {
          _processJoinGame(gameId);
        }
      }
    }
  }

  void _processJoinGame(String gameId) async {
    if (navigatorKey.currentContext != null) {
      final context = navigatorKey.currentContext!;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrieving invite details...')),
      );

      final game = await FirestoreService().getGame(gameId);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (game == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This game link is invalid or the game was deleted.')),
        );
        return;
      }

      final dateStr = "${game.scheduledTime.month}/${game.scheduledTime.day}";
      final timeStr = "${game.scheduledTime.hour}:${game.scheduledTime.minute.toString().padLeft(2, '0')}";

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Court Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You have been invited to play Pickleball!'),
              const SizedBox(height: 16),
              Text('📍 ${game.locationName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('🕒 $dateStr @ $timeStr'),
              const SizedBox(height: 8),
              Text('👤 ${game.players.length} / ${game.maxPlayers} Spots Filled'),
              const SizedBox(height: 16),
              const Text('Do you want to accept this invite?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Deny', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joining game...')),
                );
                final result = await FirestoreService().joinGame(gameId);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(result)),
                   );
                }
              },
              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
  }
}
