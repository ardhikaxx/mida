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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MIDA',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'mobile icd database application',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _labels[_selectedIndex],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _colors[_selectedIndex],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    height: 3,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _colors[_selectedIndex],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          color: theme.colorScheme.surfaceContainerHigh,
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
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: isSelected ? _colors[i] : Colors.transparent,
                  ),
                  child: Center(
                    child: Icon(
                      isSelected ? _iconsFilled[i] : _icons[i],
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
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
