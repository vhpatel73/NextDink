import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditLogAction {
  createGame,
  cancelGame,
  userLogin,
  userLogout,
  adminAccess,
}

class AuditLog {
  final String id;
  final String userId;
  final String userEmail;
  final AuditLogAction action;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      action: AuditLogAction.values.firstWhere(
        (e) => e.toString() == data['action'],
        orElse: () => AuditLogAction.createGame,
      ),
      details: data['details'] ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'action': action.toString(),
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
