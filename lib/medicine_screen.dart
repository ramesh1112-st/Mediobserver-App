import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';

class MedicineScreen extends StatefulWidget {
  final List<Map<String, String>> appointments;
  final List<Map<String, String>> medicines;
  final Function(String, String) onAddAppointment;
  final Function(String, String) onAddMedicine;
  final Function(int, String, String) onUpdateAppointment;
  final Function(int, String, String) onUpdateMedicine;
  final Function(int) onDeleteAppointment;
  final Function(int) onDeleteMedicine;

  const MedicineScreen({
    super.key,
    required this.appointments,
    required this.medicines,
    required this.onAddAppointment,
    required this.onAddMedicine,
    required this.onUpdateAppointment,
    required this.onUpdateMedicine,
    required this.onDeleteAppointment,
    required this.onDeleteMedicine,
  });

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ---------------- ADD/EDIT DIALOG ----------------
  void _showInputDialog({
    required String title,
    String? initialValue,
    required DateTime initialDate,
    int? editIndex,
    required Function(String, String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    DateTime selectedDate = initialDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("${editIndex != null ? 'Edit' : 'Add'} $title"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: "$title details"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date: "),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    String formattedDate = DateFormat(
                      'yyyy-MM-dd',
                    ).format(selectedDate);
                    onSave(formattedDate, controller.text);
                    setState(() {}); // refresh calendar
                  }
                  Navigator.pop(context);
                },
                child: Text(editIndex != null ? "Update" : "Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- CALENDAR MARKERS ----------------
  bool _hasAppointment(DateTime day) => widget.appointments.any(
    (a) => a['day'] == DateFormat('yyyy-MM-dd').format(day),
  );
  bool _hasMedicine(DateTime day) => widget.medicines.any(
    (m) => m['day'] == DateFormat('yyyy-MM-dd').format(day),
  );

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicine Calendar"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  List<Widget> markers = [];
                  if (_hasAppointment(day)) {
                    markers.add(
                      Positioned(
                        bottom: 2,
                        left: 2,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    );
                  }
                  if (_hasMedicine(day)) {
                    markers.add(
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.green,
                        ),
                      ),
                    );
                  }
                  return markers.isEmpty ? null : Stack(children: markers);
                },
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- APPOINTMENTS ----------------
            DashboardCard(
              icon: Icons.calendar_today,
              title: "Appointments",
              content: widget.appointments.isEmpty ? 'No appointments yet' : '',
              backgroundColor: Colors.teal.shade50,
              onAdd: () => _showInputDialog(
                title: "Appointment",
                initialDate: _selectedDay,
                onSave: widget.onAddAppointment,
              ),
              childList: Column(
                children: List.generate(widget.appointments.length, (index) {
                  var item = widget.appointments[index];
                  return ListTile(
                    title: Text("${item['day']}: ${item['value']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showInputDialog(
                            title: "Appointment",
                            initialValue: item['value'],
                            initialDate: DateTime.parse(item['day']!),
                            editIndex: index,
                            onSave: (day, value) =>
                                widget.onUpdateAppointment(index, day, value),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => widget.onDeleteAppointment(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- MEDICINES ----------------
            DashboardCard(
              icon: Icons.local_hospital,
              title: "Medicines",
              content: widget.medicines.isEmpty ? 'No medicines yet' : '',
              backgroundColor: Colors.teal.shade50,
              onAdd: () => _showInputDialog(
                title: "Medicine",
                initialDate: _selectedDay,
                onSave: widget.onAddMedicine,
              ),
              childList: Column(
                children: List.generate(widget.medicines.length, (index) {
                  var item = widget.medicines[index];
                  return ListTile(
                    title: Text("${item['day']}: ${item['value']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showInputDialog(
                            title: "Medicine",
                            initialValue: item['value'],
                            initialDate: DateTime.parse(item['day']!),
                            editIndex: index,
                            onSave: (day, value) =>
                                widget.onUpdateMedicine(index, day, value),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => widget.onDeleteMedicine(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
