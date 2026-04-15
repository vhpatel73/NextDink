import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';
import 'auth_service.dart';

class LoggingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  Future<void> logAction(AuditLogAction action, Map<String, dynamic> details) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('audit_logs').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Unknown',
        'action': action.toString(),
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to write audit log: $e');
    }
  }

  Stream<List<AuditLog>> getAuditLogs({String? searchQuery}) {
    Query query = _firestore.collection('audit_logs').orderBy('timestamp', descending: true);

    return query.snapshots().map((snapshot) {
      final logs = snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        return logs.where((log) {
          return log.userEmail.toLowerCase().contains(queryLower) ||
                 log.action.toString().toLowerCase().contains(queryLower) ||
                 log.details.toString().toLowerCase().contains(queryLower);
        }).toList();
      }
      
      return logs;
    });
  }
}
