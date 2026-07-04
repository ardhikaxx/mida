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

  static const _appColor = Color(0xFF00796B);

  static const _colors = [
    _appColor,
    _appColor,
    _appColor,
    _appColor,
    _appColor,
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
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 34),
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 2, 20, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'MIDA',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'mobile icd database application',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                Text(
                  _labels[_selectedIndex],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _colors[_selectedIndex],
                  ),
                ),
              ],
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
