import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/audit_log.dart';
import 'logging_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggingService _logger = LoggingService();

  // Book a new game and immediately return its Firestore ID for Deep Linking
  Future<String> createGameAndGetId(String locationName, DateTime scheduledTime) async {
    final user = _auth.currentUser;
    if (user == null) return "";

    final gameRef = _db.collection('games').doc();
    
    // Read fallback strictly from the backend in case local auth stream is desynced
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data() as Map<String, dynamic>?;
    final persistentName = data != null ? data['name'] : null;
    final persistentPhoto = data != null ? data['photoUrl'] : null;

    final determinedName = persistentName ?? user.displayName ?? user.email?.split('@')[0] ?? 'Player';
    final determinedPhoto = persistentPhoto ?? user.photoURL ?? '';

    final newGame = Game(
      id: gameRef.id,
      locationName: locationName,
      scheduledTime: scheduledTime,
      players: [user.uid],
      playerProfiles: {
        user.uid: {
          'name': determinedName,
          'email': user.email ?? '',
          'photoUrl': determinedPhoto,
        }
      },
      organizerId: user.uid,
      storedStatus: 'Scheduled',
    );

    await gameRef.set(newGame.toFirestore());

    // AUDIT LOG
    _logger.logAction(AuditLogAction.createGame, {
      'gameId': gameRef.id,
      'location': locationName,
      'time': scheduledTime.toIso8601String(),
    });

    return gameRef.id;
  }

  // Get a specific game's details
  Future<Game?> getGame(String gameId) async {
    final snapshot = await _db.collection('games').doc(gameId).get();
    if (!snapshot.exists) return null;
    return Game.fromFirestore(snapshot);
  }

  // Stream games user is part of (Cancelled + Completed filtered client-side)
  Stream<List<Game>> getUserGames() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('games')
        .where('players', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          final games = snapshot.docs
              .map((doc) => Game.fromFirestore(doc))
              .where((g) => g.isVisible) // filters out Cancelled and already Completed
              .toList();
          
          // Sort chronologically: In-progress/Soonest games first
          games.sort((a, b) {
            int cmp = a.scheduledTime.compareTo(b.scheduledTime);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id); // stability
          });
          
          return games;
        });
  }

  // Stream all games user participated in (for history view)
  Stream<List<Game>> getUserGameHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('games')
        .where('players', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          final games = snapshot.docs
              .map((doc) => Game.fromFirestore(doc))
              .toList();
          
          // Sort chronologically: Most recent first
          games.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
          
          return games;
        });
  }

  // Join a game via Deep Link ID
  Future<String> joinGame(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) return "You must be logged in to join.";

    final gameRef = _db.collection('games').doc(gameId);
    
    final result = await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(gameRef);
      if (!snapshot.exists) {
        return "This game does not exist or was deleted.";
      }

      final game = Game.fromFirestore(snapshot);
      if (game.players.contains(user.uid)) {
        return "You are already a player in this game!";
      }

      if (game.players.length >= game.maxPlayers) {
        return "This game is already full!";
      }

      // Read fallback profile directly from backend to avoid Auth Stream race conditions
      final userDoc = await transaction.get(_db.collection('users').doc(user.uid));
      final data = userDoc.data() as Map<String, dynamic>?;
      final persistentName = data != null ? data['name'] : null;
      final persistentPhoto = data != null ? data['photoUrl'] : null;

      final determinedName = persistentName ?? user.displayName ?? user.email?.split('@')[0] ?? 'Player';
      final determinedPhoto = persistentPhoto ?? user.photoURL ?? '';

      // Add the user to the array and map securely using Set/Merge instead of Update to repair legacy games
      transaction.set(gameRef, {
        'players': FieldValue.arrayUnion([user.uid]),
        'playerProfiles': {
          user.uid: {
            'name': determinedName,
            'email': user.email ?? '',
            'photoUrl': determinedPhoto,
          }
        }
      }, SetOptions(merge: true));

      return "Success";
    });

    if (result == "Success") {
      _logger.logAction(AuditLogAction.adminAccess, {
        'gameId': gameId,
        'activity': 'Player Joined Match',
      });
    }

    return result;
  }

  // Leave a game or kick a player
  Future<void> leaveGame(String gameId, [String? targetUid]) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final uidToRemove = targetUid ?? user.uid;
    final gameRef = _db.collection('games').doc(gameId);
    
    await gameRef.update({
      'players': FieldValue.arrayRemove([uidToRemove]),
      'playerProfiles.$uidToRemove': FieldValue.delete(),
    });

    _logger.logAction(AuditLogAction.adminAccess, {
      'gameId': gameId,
      'activity': 'Player Left Match',
      'targetUid': uidToRemove,
    });
  }

  // Soft-cancel a game: marks status as 'Cancelled', never deletes the record
  Future<void> cancelGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({'status': 'Cancelled'});
    
    _logger.logAction(AuditLogAction.cancelGame, {
      'gameId': gameId,
    });
  }
}
