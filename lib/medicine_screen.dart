import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart'; // ✅ for local notifications

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Add Medicine + Reminder
  Future<void> addMedicine() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _medNameController.text.trim();
    final dosage = _dosageController.text.trim();
    final time = _timeController.text.trim();

    if (name.isEmpty || dosage.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    // 🩺 Save to Firestore
    await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('medicines')
    .add({
  'medicineName': _medNameController.text,
  'dosage': _dosageController.text,
  'time': _timeController.text,
  'createdAt': FieldValue.serverTimestamp(),
});


    // 🔔 Schedule Daily Notification
    try {
      final timeParts = time.split(":");
      int hour = int.parse(timeParts[0]);
      int minute = 0;
      bool isPM = time.toLowerCase().contains("pm");

      // Adjust for PM
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      // If "8:30 AM" type, handle minutes
      if (timeParts.length > 1) {
        final minText = timeParts[1].split(" ")[0];
        minute = int.tryParse(minText) ?? 0;
      }

      await NotificationService.scheduleDailyNotification(
        title: "💊 Medicine Reminder",
        body: "It's time to take $name ($dosage)",
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }

    // Clear fields
    _medNameController.clear();
    _dosageController.clear();
    _timeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Medicine added & reminder set!")),
    );
  }

  // ✅ Real-time medicine stream
  Stream<QuerySnapshot> getMedicines() {
    final user = _auth.currentUser;
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('medicines')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Tracker 💊'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _medNameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 1 tablet)',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time (e.g., 8:00 AM)',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: addMedicine,
              child: const Text('Add Medicine'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Your Medicines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getMedicines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No medicines added yet.'));
                  }

                  final medicines = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final med = medicines[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.medical_services, color: Colors.teal),
                          title: Text(med['medicineName'] ?? 'Unknown'),
                          subtitle: Text(
                            "Dosage: ${med['dosage'] ?? ''}\nTime: ${med['time'] ?? ''}",
                          ),
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
