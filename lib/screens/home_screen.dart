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

  static const _labels = [
    'ICD-10',
    'ICD-MM',
    'ICD-PM',
    'ICD-O',
    'ICD-9-CM',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_selectedIndex]),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_types.length, (i) {
          return SearchScreen(type: _types[i], color: _colors[i]);
        }),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              elevation: 0,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              indicatorColor: _colors[_selectedIndex].withValues(alpha: 0.15),
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: List.generate(_types.length, (i) {
                return NavigationDestination(
                  icon: Icon(_icons[i], color: theme.colorScheme.onSurfaceVariant),
                  selectedIcon: Icon(_icons[i], color: _colors[i]),
                  label: _labels[i],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
