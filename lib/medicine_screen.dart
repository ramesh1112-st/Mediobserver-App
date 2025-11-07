import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add Medicine
  Future<void> addMedicine() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _medNameController.text.trim();
    final dosage = _dosageController.text.trim();

    if (name.isEmpty ||
        dosage.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fill all fields and select date/time"),
        ),
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .add({
          'medicineName': name,
          'dosage': dosage,
          'datetime': Timestamp.fromDate(dateTime),
          'createdAt': FieldValue.serverTimestamp(),
        });

    // Schedule notification
    try {
      await NotificationService.scheduleDailyNotification(
        title: "💊 Medicine Reminder",
        body: "It's time to take $name ($dosage)",
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }

    _medNameController.clear();
    _dosageController.clear();
    _selectedDate = null;
    _selectedTime = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Medicine added & reminder set!")),
    );

    setState(() {});
  }

  // Delete Medicine
  Future<void> deleteMedicine(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .doc(docId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Medicine deleted successfully")),
    );
  }

  // Edit Medicine
  void editMedicine(String docId, Map<String, dynamic> medData) {
    _medNameController.text = medData['medicineName'] ?? '';
    _dosageController.text = medData['dosage'] ?? '';

    if (medData['datetime'] is Timestamp) {
      final dateTime = (medData['datetime'] as Timestamp).toDate();
      _selectedDate = dateTime;
      _selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Medicine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _medNameController,
                decoration: const InputDecoration(labelText: "Medicine Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: "Dosage"),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.teal,
                      ),
                      label: Text(
                        _selectedDate == null
                            ? "Select Date"
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      ),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null)
                          setState(() => _selectedDate = pickedDate);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, color: Colors.teal),
                      label: Text(
                        _selectedTime == null
                            ? "Select Time"
                            : _selectedTime!.format(context),
                      ),
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null)
                          setState(() => _selectedTime = pickedTime);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final user = _auth.currentUser;
                if (user == null) return;

                if (_selectedDate == null || _selectedTime == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("⚠️ Please select date & time"),
                      ),
                    );
                  }
                  return;
                }

                final updatedDateTime = DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                );

                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('medicines')
                    .doc(docId)
                    .update({
                      'medicineName': _medNameController.text.trim(),
                      'dosage': _dosageController.text.trim(),
                      'datetime': Timestamp.fromDate(updatedDateTime),
                    });

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Medicine updated successfully"),
                  ),
                );

                _medNameController.clear();
                _dosageController.clear();
                _selectedDate = null;
                _selectedTime = null;

                setState(() {});
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> getMedicines() {
    final user = _auth.currentUser;
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('medicines')
        .orderBy('datetime', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Medicine Tracker 💊'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input Card
            Center(
              child: SizedBox(
                width: screenWidth * 0.7,
                child: Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.medication,
                          color: Colors.teal,
                          size: 50,
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _medNameController,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name',
                            prefixIcon: Icon(Icons.medication),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Dosage (e.g., 1 tablet)',
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.teal,
                                ),
                                label: Text(
                                  _selectedDate == null
                                      ? "Select Date"
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_selectedDate!),
                                ),
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null)
                                    setState(() => _selectedDate = pickedDate);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.access_time,
                                  color: Colors.teal,
                                ),
                                label: Text(
                                  _selectedTime == null
                                      ? "Select Time"
                                      : _selectedTime!.format(context),
                                ),
                                onPressed: () async {
                                  final pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        _selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (pickedTime != null)
                                    setState(() => _selectedTime = pickedTime);
                                },
                              ),
                            ),
                          ],
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Medicine List
            StreamBuilder<QuerySnapshot>(
              stream: getMedicines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final medicines = snapshot.data!.docs;
                if (medicines.isEmpty) return const Text("No medicines added");

                return Column(
                  children: medicines.map((doc) {
                    final med = doc.data() as Map<String, dynamic>;
                    DateTime? dateTime;
                    if (med['datetime'] is Timestamp)
                      dateTime = (med['datetime'] as Timestamp).toDate();

                    return Center(
                      child: SizedBox(
                        width: screenWidth * 0.7,
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(
                              Icons.medication,
                              color: Colors.teal,
                            ),
                            title: Text(med['medicineName'] ?? 'Unknown'),
                            subtitle: dateTime != null
                                ? Text(
                                    "Dosage: ${med['dosage']}\nDate: ${DateFormat('dd MMM yyyy - hh:mm a').format(dateTime)}",
                                  )
                                : Text("Dosage: ${med['dosage']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => editMedicine(doc.id, med),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteMedicine(doc.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
