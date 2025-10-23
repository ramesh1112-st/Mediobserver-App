import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key}); // no email parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.account_circle, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'test@example.com', // static email
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Notification Section
            ProfileButton(
              icon: Icons.notifications,
              text: 'Notifications',
              onTap: () {
                // Add your notification logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications tapped')),
                );
              },
            ),

            // Theme Section
            ProfileButton(
              icon: Icons.color_lens,
              text: 'Theme',
              onTap: () {
                // Add your theme change logic here
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Theme tapped')));
              },
            ),

            // Settings Section
            ProfileButton(
              icon: Icons.settings,
              text: 'Settings',
              onTap: () {
                // Add your settings logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings tapped')),
                );
              },
            ),

            const SizedBox(height: 20),

            // Logout Button
            ProfileButton(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
