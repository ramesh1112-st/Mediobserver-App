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

  // Steps Tracking
  int _todaySteps = 0;
  final int _stepGoal = 10000;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Today's Medicines
      _todayMedicinesStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .where(
            'datetime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('datetime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('datetime', descending: false)
          .snapshots();

      // Today's Appointments
      _todayAppointmentsStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: false)
          .snapshots();
    }
  }

  // ---------------- Steps Tracker ----------------
  Widget _buildStepsSection() {
    double progress = (_todaySteps / _stepGoal).clamp(0.0, 1.0);

    return _buildSectionContainer(
      title: "Steps Tracker",
      child: Column(
        children: [
          Text(
            _todaySteps.toString(),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Colors.teal),
          ),
          const SizedBox(height: 8),
          Text(
            "Goal: ${NumberFormat('#,###').format(_stepGoal)} steps",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
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
                iconSize: 35,
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () {
                  setState(() {
                    _todaySteps += 100;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green,
                iconSize: 35,
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () {
                  setState(() {
                    _todaySteps = 0;
                  });
                },
                icon: const Icon(Icons.refresh),
                color: Colors.teal,
                iconSize: 35,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Today's Medicines ----------------
  Widget _buildMedicineSection() {
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

          final medicines = snapshot.data!.docs;

          return Column(
            children: medicines.map((doc) {
              final med = doc.data() as Map<String, dynamic>;
              String time = 'N/A';
              if (med['datetime'] is Timestamp) {
                final dateTime = (med['datetime'] as Timestamp).toDate();
                time = DateFormat('hh:mm a').format(dateTime);
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

  // ---------------- Today's Appointments ----------------
  Widget _buildAppointmentsSection() {
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

          final appointments = snapshot.data!.docs;

          return Column(
            children: appointments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String dateTimeStr = 'Unknown Time';
              if (data['date'] is Timestamp) {
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

  // ---------------- Build HomeScreen ----------------
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in first.")));
    }

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
              _buildStepsSection(),
              const SizedBox(height: 20),
              _buildMedicineSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Helper: Section Card ----------------
  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double containerWidth = screenWidth * 0.7;

        return Align(
          alignment: Alignment.center,
          child: Container(
            width: containerWidth,
            margin: const EdgeInsets.symmetric(vertical: 10),
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
}
