import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String locationName;
  final DateTime scheduledTime;
  final List<String> players;
  final Map<String, Map<String, String>> playerProfiles;
  final int maxPlayers;

  Game({
    required this.id,
    required this.locationName,
    required this.scheduledTime,
    required this.players,
    required this.playerProfiles,
    this.maxPlayers = 4,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse nested map safely
    final rawProfiles = data['playerProfiles'] as Map<String, dynamic>? ?? {};
    final parsedProfiles = <String, Map<String, String>>{};
    rawProfiles.forEach((key, value) {
      if (value is Map) {
        parsedProfiles[key] = Map<String, String>.from(value);
      }
    });

    return Game(
      id: doc.id,
      locationName: data['locationName'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      players: List<String>.from(data['players'] ?? []),
      playerProfiles: parsedProfiles,
      maxPlayers: data['maxPlayers'] ?? 4,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'locationName': locationName,
      'scheduledTime': scheduledTime,
      'players': players,
      'playerProfiles': playerProfiles,
      'maxPlayers': maxPlayers,
    };
  }
}
