import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/audit_log.dart';
import '../services/logging_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'System Audit Logs',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by email, action, or details...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AuditLog>>(
              stream: LoggingService().getAuditLogs(searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No logs found.'));
                }

                final logs = snapshot.data!;
                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      title: Text(
                        log.action.toString().split('.').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${log.userEmail}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          Text('Details: ${log.details}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      trailing: Text(
                        DateFormat('MMM d, HH:mm').format(log.timestamp),
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
