import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/icd_service.dart';
import 'about_screen.dart';
import 'code_validator_screen.dart';
import 'coding_guidelines_screen.dart';
import 'diagnosis_screen.dart';
import 'generator_screen.dart';
import 'icd_tree_screen.dart';
import 'medical_dict_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

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
    Icons.monitor_heart_outlined,
    Icons.health_and_safety_outlined,
    Icons.healing_outlined,
  ];

  static const _iconsFilled = [
    Icons.medical_services,
    Icons.pregnant_woman,
    Icons.monitor_heart,
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
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 70),
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
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo-app.png',
                    height: 36,
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.labelSmall,
                    children: [
                      TextSpan(
                        text: 'MIDA\n',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 22,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'mobile icd database application',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _labels[_selectedIndex],
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _colors[_selectedIndex],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  color: theme.colorScheme.surfaceContainer,
                  elevation: 8,
                  shadowColor: theme.shadowColor.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  position: PopupMenuPosition.under,
                  onSelected: (v) {
                    Widget screen;
                    switch (v) {
                      case 'diagnosis':
                        screen = const DiagnosisScreen();
                        break;
                      case 'tree':
                        screen = const IcdTreeScreen();
                        break;
                      case 'dict':
                        screen = const MedicalDictScreen();
                        break;
                      case 'generator':
                        screen = const GeneratorScreen();
                        break;
                      case 'validator':
                        screen = const CodeValidatorScreen();
                        break;
                      case 'guidelines':
                        screen = const CodingGuidelinesScreen();
                        break;
                      case 'settings':
                        screen = const SettingsScreen();
                        break;
                      case 'about':
                        screen = const AboutScreen();
                        break;
                      default:
                        return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'diagnosis',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.healing_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Diagnosis → ICD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'tree',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.account_tree_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Pohon ICD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'dict',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.menu_book_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Glosarium Medis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'generator',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.auto_fix_high_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Cari Berdasarkan Gejala', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(height: 4),
                    PopupMenuItem(
                      value: 'validator',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.verified_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Cek Validasi Kode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'guidelines',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.assignment_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Panduan Pengkodean', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(height: 4),
                    PopupMenuItem(
                      value: 'settings',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.settings_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(width: 12),
                          Text('Pengaturan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'about',
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 12),
                          const Text('Tentang MIDA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
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
                onTap: () {
                  if (hapticNotifier.value) HapticFeedback.selectionClick();
                  setState(() => _selectedIndex = i);
                },
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
