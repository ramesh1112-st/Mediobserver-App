import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'medicine_screen.dart';
import 'profile_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  List<Map<String, String>> appointments = [];
  List<Map<String, String>> medicines = [];

  void _addAppointment(String day, String value) =>
      appointments.add({'day': day, 'value': value});
  void _updateAppointment(int index, String day, String value) =>
      appointments[index] = {'day': day, 'value': value};
  void _deleteAppointment(int index) => appointments.removeAt(index);

  void _addMedicine(String day, String value) =>
      medicines.add({'day': day, 'value': value});
  void _updateMedicine(int index, String day, String value) =>
      medicines[index] = {'day': day, 'value': value};
  void _deleteMedicine(int index) => medicines.removeAt(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          HomeScreen(appointments: appointments, medicines: medicines),
          MedicineScreen(
            appointments: appointments,
            medicines: medicines,
            onAddAppointment: _addAppointment,
            onAddMedicine: _addMedicine,
            onUpdateAppointment: _updateAppointment,
            onUpdateMedicine: _updateMedicine,
            onDeleteAppointment: _deleteAppointment,
            onDeleteMedicine: _deleteMedicine,
          ),
          const ProfileScreen(), // static profile screen
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Medicine',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
