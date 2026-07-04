import 'dart:ui' as ui;
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

  static const _iconsFilled = [
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
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_types.length, (i) {
          return SearchScreen(type: _types[i], color: _colors[i]);
        }),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Row(
                children: List.generate(_types.length, (i) {
                  final isSelected = _selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.all(isSelected ? 6 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isSelected
                              ? _colors[i].withValues(alpha: 0.15)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? _iconsFilled[i] : _icons[i],
                              color: isSelected ? _colors[i] : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: isSelected
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _labels[i],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _colors[i],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
