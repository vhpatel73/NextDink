import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Book a new game
  Future<void> bookGame(String locationName, DateTime scheduledTime) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final gameRef = _db.collection('games').doc();
    
    final newGame = Game(
      id: gameRef.id,
      locationName: locationName,
      scheduledTime: scheduledTime,
      players: [user.uid], // Creator gets the first spot
    );

    await gameRef.set(newGame.toFirestore());
  }

  // Stream games user is part of
  Stream<List<Game>> getUserGames() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('games')
        .where('players', arrayContains: user.uid)
        // Ordering by time might require a composite index in production
        // so we retrieve it ordered by default Firebase rules and sort local
        .snapshots()
        .map((snapshot) {
          final games = snapshot.docs
              .map((doc) => Game.fromFirestore(doc))
              .toList();
          games.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          return games;
        });
  }

  // Join a game via Deep Link ID
  Future<String> joinGame(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) return "You must be logged in to join.";

    final gameRef = _db.collection('games').doc(gameId);
    
    return await _db.runTransaction((transaction) async {
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

      // Add the user to the array
      transaction.update(gameRef, {
        'players': FieldValue.arrayUnion([user.uid])
      });

      return "Success";
    });
  }
}
