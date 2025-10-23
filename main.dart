import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

void main() {
  runApp(const MediObserverApp());
}

class MediObserverApp extends StatelessWidget {
  const MediObserverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediObserver',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const OnboardingScreen(),
    );
  }
}
