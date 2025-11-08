import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Notification reminders', style: TextStyle(fontSize: 16)),
          SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Email Updates')),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.displayName ?? user.email!),
            subtitle: const Text('About'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
