import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot>? _todayMedicinesStream;
  Stream<QuerySnapshot>? _todayAppointmentsStream;
  Stream<QuerySnapshot>? _bpDataStream;

  int _todaySteps = 0;
  final int _stepGoal = 10000;

  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  DateTime? _selectedBPDateTime;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;

    if (user != null) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Today’s medicines (with daily ones)
      _todayMedicinesStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .where(
            'datetime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('datetime', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots();

      // Today’s appointments
      _todayAppointmentsStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .snapshots();

      // BP readings stream
      _bpDataStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bp_readings')
          .orderBy('datetime', descending: true)
          .snapshots();
    }
  }

  // ---------------- BP Save ----------------
  Future<void> _saveBPReading() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final systolic = _systolicController.text.trim();
    final diastolic = _diastolicController.text.trim();
    if (systolic.isEmpty || diastolic.isEmpty || _selectedBPDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and pick a time."),
        ),
      );
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bp_readings')
        .add({
          'systolic': systolic,
          'diastolic': diastolic,
          'datetime': Timestamp.fromDate(_selectedBPDateTime!),
        });

    _systolicController.clear();
    _diastolicController.clear();
    setState(() => _selectedBPDateTime = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("BP Reading Saved Successfully")),
    );
  }

  void _showBPDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("BP Readings"),
        content: StreamBuilder<QuerySnapshot>(
          stream: _bpDataStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text("No BP data found.");
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView(
                children: docs.map((doc) {
                  final data = Map<String, dynamic>.from(doc.data() as Map);
                  final time = DateFormat(
                    'dd MMM, hh:mm a',
                  ).format((data['datetime'] as Timestamp).toDate());
                  return ListTile(
                    title: Text(
                      "BP: ${data['systolic']}/${data['diastolic']} mmHg",
                    ),
                    subtitle: Text("Time: $time"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await doc.reference.delete();
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ---------------- Medicines Section ----------------
  Widget _buildMedicineSection() {
    final now = DateTime.now();
    return _buildSectionContainer(
      title: "Today's Medicines",
      child: StreamBuilder<QuerySnapshot>(
        stream: _todayMedicinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text("No medicines for today.");
          }

          final medicines = snapshot.data!.docs.where((doc) {
            final med = Map<String, dynamic>.from(doc.data() as Map);
            final isDaily = med['isDaily'] == true;
            final date = med['datetime'] is Timestamp
                ? (med['datetime'] as Timestamp).toDate()
                : null;
            return isDaily ||
                (date != null &&
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day);
          }).toList();

          if (medicines.isEmpty) return const Text("No medicines for today.");

          return Column(
            children: medicines.map((doc) {
              final med = Map<String, dynamic>.from(doc.data() as Map);
              String time = 'N/A';
              if (med['isDaily'] == true) {
                time = "Daily";
              } else if (med['datetime'] is Timestamp) {
                time = DateFormat(
                  'hh:mm a',
                ).format((med['datetime'] as Timestamp).toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.medication, color: Colors.teal),
                  title: Text(med['medicineName'] ?? 'Unknown'),
                  subtitle: Text(
                    "Dosage: ${med['dosage'] ?? 'N/A'} | Time: $time",
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ---------------- Appointments Section ----------------
  Widget _buildAppointmentsSection() {
    final now = DateTime.now();
    return _buildSectionContainer(
      title: "Today's Appointments",
      child: StreamBuilder<QuerySnapshot>(
        stream: _todayAppointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text("No appointments for today.");
          }

          final appointments = snapshot.data!.docs.where((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            final isDaily = data['isDaily'] == true;
            final date = data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : null;
            return isDaily ||
                (date != null &&
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day);
          }).toList();

          if (appointments.isEmpty) {
            return const Text("No appointments for today.");
          }

          return Column(
            children: appointments.map((doc) {
              final data = Map<String, dynamic>.from(doc.data() as Map);
              String dateTimeStr = 'Unknown Time';
              if (data['isDaily'] == true) {
                dateTimeStr = "Daily";
              } else if (data['date'] is Timestamp) {
                dateTimeStr = DateFormat(
                  'hh:mm a',
                ).format((data['date'] as Timestamp).toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: Text(data['doctor'] ?? 'Unknown Doctor'),
                  subtitle: Text(
                    "Specialty: ${data['specialty'] ?? 'N/A'}\nTime: $dateTimeStr",
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ---------------- Steps Tracker ----------------
  Widget _buildStepsCardInner() {
    double progress = (_todaySteps / _stepGoal).clamp(0.0, 1.0);

    return _buildInnerCard(
      title: "Steps Tracker",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                _todaySteps.toString(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation(Colors.teal),
              ),
              const SizedBox(height: 8),
              Text(
                "Goal: ${NumberFormat('#,###').format(_stepGoal)} steps",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _todaySteps = (_todaySteps - 100).clamp(0, _stepGoal);
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _todaySteps += 100;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _todaySteps = 0;
                  });
                },
                icon: const Icon(Icons.refresh),
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- BP Tracker ----------------
  Widget _buildBPCardInner() {
    return _buildInnerCard(
      title: "BP Tracker",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              TextField(
                controller: _systolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Systolic (mmHg)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Diastolic (mmHg)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    color: Colors.teal,
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time == null) return;
                      setState(() {
                        _selectedBPDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  Text(
                    _selectedBPDateTime == null
                        ? "No Time Selected"
                        : DateFormat(
                            'dd MMM, hh:mm a',
                          ).format(_selectedBPDateTime!),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _saveBPReading,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.dataset, color: Colors.teal),
                label: const Text("Data", style: TextStyle(color: Colors.teal)),
                onPressed: _showBPDataDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Build UI ----------------
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in first.")));
    }

    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("MediObserver"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              _buildAppointmentsSection(),
              const SizedBox(height: 20),
              _buildSectionContainer(
                title: "Health Tracker",
                child: isWideScreen
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildStepsCardInner()),
                            const SizedBox(width: 10),
                            Expanded(child: _buildBPCardInner()),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _buildStepsCardInner(),
                          const SizedBox(height: 10),
                          _buildBPCardInner(),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              _buildMedicineSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Reusable Containers ----------------
  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double containerWidth = screenWidth * 0.85;
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: containerWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInnerCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.teal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
