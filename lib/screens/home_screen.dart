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
    Icons.medical_services_outlined,
    Icons.pregnant_woman_outlined,
    Icons.child_care_outlined,
    Icons.health_and_safety_outlined,
    Icons.healing_outlined,
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
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_types.length, (i) {
          return SearchScreen(type: _types[i], color: _colors[i]);
        }),
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_types.length, (i) {
            final isSelected = _selectedIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  margin: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: isSelected ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? _colors[i].withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: isSelected
                          ? Padding(
                              key: const ValueKey('text'),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                _labels[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _colors[i],
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          : Padding(
                              key: const ValueKey('icon'),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                _icons[i],
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
