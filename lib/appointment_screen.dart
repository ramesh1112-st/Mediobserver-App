import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isDaily = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add Appointment
  Future<void> addAppointment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doctor = _doctorController.text.trim();
    final specialty = _specialtyController.text.trim();

    // if not Daily ensure date & time are selected
    if (doctor.isEmpty ||
        specialty.isEmpty ||
        (!_isDaily && (_selectedDate == null || _selectedTime == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Please fill all fields and select date/time or choose Daily",
          ),
        ),
      );
      return;
    }

    Map<String, dynamic> payload = {
      'doctor': doctor,
      'specialty': specialty,
      'isDaily': _isDaily,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (!_isDaily) {
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      payload['date'] = Timestamp.fromDate(appointmentDateTime);
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('appointments')
        .add(payload);

    _doctorController.clear();
    _specialtyController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _isDaily = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Appointment added successfully")),
    );

    setState(() {});
  }

  // Delete Appointment
  Future<void> deleteAppointment(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('appointments')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Appointment deleted successfully")),
    );
  }

  // Edit Appointment
  void editAppointment(String docId, Map<String, dynamic> data) {
    _doctorController.text = data['doctor'] ?? '';
    _specialtyController.text = data['specialty'] ?? '';
    _isDaily = data['isDaily'] == true;

    DateTime? existingDate;
    if (data['date'] is Timestamp) {
      existingDate = (data['date'] as Timestamp).toDate();
    }

    setState(() {
      _selectedDate = existingDate;
      _selectedTime = existingDate != null
          ? TimeOfDay(hour: existingDate.hour, minute: existingDate.minute)
          : null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Appointment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _doctorController,
                decoration: const InputDecoration(labelText: "Doctor Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: "Specialty"),
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
                      onPressed: _isDaily
                          ? null
                          : () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() => _selectedDate = pickedDate);
                              }
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
                      onPressed: _isDaily
                          ? null
                          : () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setState(() => _selectedTime = pickedTime);
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text("Repeat Daily"),
                value: _isDaily,
                onChanged: (val) {
                  setState(() {
                    _isDaily = val ?? false;
                    if (_isDaily) {
                      _selectedDate = null;
                      _selectedTime = null;
                    }
                  });
                },
                activeColor: Colors.teal,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final user = _auth.currentUser;
                if (user == null) return;

                if (!_isDaily &&
                    (_selectedDate == null || _selectedTime == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "⚠️ Please select date & time or choose Daily",
                      ),
                    ),
                  );
                  return;
                }

                Map<String, dynamic> updated = {
                  'doctor': _doctorController.text.trim(),
                  'specialty': _specialtyController.text.trim(),
                  'isDaily': _isDaily,
                };

                if (_isDaily) {
                  updated['date'] = null;
                } else {
                  final appointmentDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );
                  updated['date'] = Timestamp.fromDate(appointmentDateTime);
                }

                final docRef = _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('appointments')
                    .doc(docId);

                await docRef.update(updated);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Appointment updated successfully"),
                  ),
                );

                _doctorController.clear();
                _specialtyController.clear();
                _selectedDate = null;
                _selectedTime = null;
                _isDaily = false;

                setState(() {});
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // Use full appointments stream
  Stream<QuerySnapshot> getAppointments() {
    final user = _auth.currentUser;
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('appointments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Appointments 📅'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
                          Icons.calendar_today,
                          color: Colors.teal,
                          size: 50,
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _doctorController,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _specialtyController,
                          decoration: const InputDecoration(
                            labelText: 'Specialty',
                            prefixIcon: Icon(Icons.medical_services),
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
                                onPressed: _isDaily
                                    ? null
                                    : () async {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _selectedDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (pickedDate != null) {
                                          setState(
                                            () => _selectedDate = pickedDate,
                                          );
                                        }
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
                                onPressed: _isDaily
                                    ? null
                                    : () async {
                                        final pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime:
                                              _selectedTime ?? TimeOfDay.now(),
                                        );
                                        if (pickedTime != null) {
                                          setState(
                                            () => _selectedTime = pickedTime,
                                          );
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: const Text("Repeat Daily"),
                          value: _isDaily,
                          onChanged: (val) {
                            setState(() {
                              _isDaily = val ?? false;
                              if (_isDaily) {
                                _selectedDate = null;
                                _selectedTime = null;
                              }
                            });
                          },
                          activeColor: Colors.teal,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: addAppointment,
                          child: const Text('Add Appointment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: getAppointments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final appointments = snapshot.data!.docs;
                if (appointments.isEmpty) {
                  return const Text("No appointments added.");
                }

                return Column(
                  children: appointments.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    DateTime? dateTime;
                    if (data['date'] is Timestamp) {
                      dateTime = (data['date'] as Timestamp).toDate();
                    }
                    final isDaily = data['isDaily'] == true;

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
                              Icons.calendar_today,
                              color: Colors.teal,
                            ),
                            title: Text(data['doctor'] ?? 'Unknown Doctor'),
                            subtitle: Text(
                              isDaily
                                  ? "Specialty: ${data['specialty'] ?? ''}\nRepeats: Daily"
                                  : "Specialty: ${data['specialty'] ?? ''}\nDate: ${dateTime != null ? DateFormat('dd MMM yyyy - hh:mm a').format(dateTime) : 'N/A'}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      editAppointment(doc.id, data),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteAppointment(doc.id),
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
