import 'package:flutter/material.dart';

// ---------------- STAT CARD ----------------
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// ---------------- MEDICINE TILE ----------------
class MedicineTile extends StatelessWidget {
  final String name;
  final String time;
  const MedicineTile({super.key, required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication_liquid, color: Colors.teal),
        title: Text(name),
        trailing: Text(time),
      ),
    );
  }
}

// ---------------- DASHBOARD CARD ----------------
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color backgroundColor;
  final VoidCallback onAdd;
  final Widget? childList; // Optional child list for edit/delete

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.backgroundColor,
    required this.onAdd,
    this.childList,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            childList ?? Text(content),
          ],
        ),
      ),
    );
  }
}
