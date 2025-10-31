import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart'; // ✅ Import notification service

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _addAppointment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doctor = _doctorController.text.trim();
    final dateText = _dateController.text.trim();

    if (doctor.isEmpty || dateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // 🗓 Parse date from text
    // Expected input format: 5 Nov, 10:00 AM
    DateTime? parsedDate;
    try {
      // For now, just schedule it 10 seconds later for testing
      parsedDate = DateTime.now().add(const Duration(seconds: 10));
      // (You can replace this with proper parsing later)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid date format")),
      );
      return;
    }

    // ✅ Save in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('appointments')
        .add({
      'doctor': doctor,
      'date': dateText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ Schedule notification
    await NotificationService.scheduleSingleNotification(
      title: "📅 Appointment Reminder",
      body: "You have an appointment with Dr. $doctor at $dateText",
      dateTime: parsedDate,
    );

    // Clear text fields
    _doctorController.clear();
    _dateController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment added & reminder set!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text("No user logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Appointments"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _doctorController,
              decoration: const InputDecoration(
                labelText: "Doctor Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: "Date & Time (e.g. 5 Nov, 10 AM)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("Add Appointment"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('appointments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final appointments = snapshot.data?.docs ?? [];
                  if (appointments.isEmpty) {
                    return const Center(child: Text("No appointments added yet"));
                  }

                  return ListView.builder(
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final data =
                          appointments[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.teal),
                          title: Text(data['doctor'] ?? 'Unknown'),
                          subtitle: Text(data['date'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
