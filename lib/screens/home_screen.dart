import 'package:flutter/material.dart';
import '../services/icd_service.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _types = [
    IcdClassification.icd10,
    IcdClassification.icdMM,
    IcdClassification.icdPM,
    IcdClassification.icdO,
    IcdClassification.icd9CM,
  ];

  static const _colors = [
    Color(0xFF0077B6),
    Color(0xFFD63384),
    Color(0xFF6F42C1),
    Color(0xFFE85D04),
    Color(0xFF2D6A4F),
  ];

  static const _icons = [
    Icons.medical_services,
    Icons.pregnant_woman,
    Icons.child_care,
    Icons.health_and_safety,
    Icons.healing,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_types[_selectedIndex].label),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_types.length, (i) {
          return SearchScreen(type: _types[i], color: _colors[i]);
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: List.generate(_types.length, (i) {
          return NavigationDestination(
            icon: Icon(_icons[i]),
            label: _types[i].label,
          );
        }),
      ),
    );
  }
}
