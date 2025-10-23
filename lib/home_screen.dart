import 'package:flutter/material.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, String>> appointments;
  final List<Map<String, String>> medicines;

  const HomeScreen({
    super.key,
    required this.appointments,
    required this.medicines,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int waterIntake = 0;

  void _incrementWater() {
    setState(() {
      waterIntake += 100;
    });
  }

  void _decrementWater() {
    setState(() {
      if (waterIntake >= 100) waterIntake -= 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediObserver'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Today's Appointments",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            widget.appointments.isNotEmpty
                ? Column(
                    children: widget.appointments
                        .map(
                          (a) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text("${a['day']}: ${a['value']}"),
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No appointments yet'),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text(
              'Health Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const StatCard(label: 'Steps', value: '5230'),
                const StatCard(label: 'BP', value: '120/80'),
                Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              "${waterIntake}g",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text("Water"),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.teal,
                                  ),
                                  onPressed: _decrementWater,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.teal,
                                  ),
                                  onPressed: _incrementWater,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Medicine Reminders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            widget.medicines.isNotEmpty
                ? Column(
                    children: widget.medicines
                        .map(
                          (m) => MedicineTile(
                            name: "${m['day']}: ${m['value']}",
                            time: '—',
                          ),
                        )
                        .toList(),
                  )
                : const MedicineTile(name: 'No medicines yet', time: ''),
          ],
        ),
      ),
    );
  }
}
