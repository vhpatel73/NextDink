import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(indent: 64, endIndent: 64, color: Colors.white10),
          const SizedBox(height: 24),
          const Text(
            'NextDink v1.1',
            style: TextStyle(
              color: Colors.white38, 
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dink responsibly! 🥒',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerLink('Privacy'),
              _footerBullet(),
              _footerLink('Terms'),
              _footerBullet(),
              _footerLink('Support'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2026 NextDink',
            style: TextStyle(color: Colors.white10, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return GestureDetector(
      onTap: () {}, // Placeholders
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white24, 
          fontSize: 10, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _footerBullet() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Text('•', style: TextStyle(color: Colors.white12, fontSize: 10)),
    );
  }
}
