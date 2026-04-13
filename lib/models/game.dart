import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String locationName;
  final DateTime scheduledTime;
  final List<String> players;
  final int maxPlayers;

  Game({
    required this.id,
    required this.locationName,
    required this.scheduledTime,
    required this.players,
    this.maxPlayers = 4,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      locationName: data['locationName'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      players: List<String>.from(data['players'] ?? []),
      maxPlayers: data['maxPlayers'] ?? 4,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'locationName': locationName,
      'scheduledTime': scheduledTime,
      'players': players,
      'maxPlayers': maxPlayers,
    };
  }
}
