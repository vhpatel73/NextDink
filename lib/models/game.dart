import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus { scheduled, inProgress, completed, cancelled }

class Game {
  final String id;
  final String locationName;
  final DateTime scheduledTime;
  final List<String> players;
  final Map<String, Map<String, String>> playerProfiles;
  final String organizerId;
  final int maxPlayers;
  /// Stored in Firestore only for 'cancelled'. All other statuses are computed.
  final String _storedStatus;

  Game({
    required this.id,
    required this.locationName,
    required this.scheduledTime,
    required this.players,
    required this.playerProfiles,
    required this.organizerId,
    this.maxPlayers = 4,
    String storedStatus = 'Scheduled',
  }) : _storedStatus = storedStatus;

  /// Computed status based on scheduledTime and stored cancellation flag.
  GameStatus get status {
    if (_storedStatus == 'Cancelled') return GameStatus.cancelled;
    final now = DateTime.now();
    final end = scheduledTime.add(const Duration(hours: 2));
    if (now.isBefore(scheduledTime)) return GameStatus.scheduled;
    if (now.isBefore(end)) return GameStatus.inProgress;
    return GameStatus.completed;
  }

  String get statusLabel {
    switch (status) {
      case GameStatus.scheduled:   return 'Scheduled';
      case GameStatus.inProgress:  return 'In Progress';
      case GameStatus.completed:   return 'Completed';
      case GameStatus.cancelled:   return 'Cancelled';
    }
  }

  bool get isVisible =>
      status == GameStatus.scheduled || status == GameStatus.inProgress;

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

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
      organizerId: data['organizerId'] ?? (data['players'] as List?)?.first ?? '',
      maxPlayers: data['maxPlayers'] ?? 4,
      storedStatus: data['status'] ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'locationName': locationName,
      'scheduledTime': scheduledTime,
      'players': players,
      'playerProfiles': playerProfiles,
      'organizerId': organizerId,
      'maxPlayers': maxPlayers,
      'status': _storedStatus,
    };
  }
}
