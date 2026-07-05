import 'package:flutter/material.dart';
import '../services/icd_service.dart';

class CodeValidatorScreen extends StatefulWidget {
  const CodeValidatorScreen({super.key});

  @override
  State<CodeValidatorScreen> createState() => _CodeValidatorScreenState();
}

class _CodeValidatorScreenState extends State<CodeValidatorScreen> {
  final _codeController = TextEditingController();
  final IcdService _service = IcdService();
  IcdClassification _selectedType = IcdClassification.icd10;
  bool _isLoading = false;
  List<_ValidationResult> _results = [];

  static final Map<IcdClassification, _ValidationRule> _rules = {
    IcdClassification.icd10: _ValidationRule(
      label: 'ICD-10',
      pattern: r'^[A-Za-z]\d{2}(\.\d{0,2})?$',
      format: 'X##.##\n1 huruf + 2 digit, opsional . + 1-2 digit\nContoh: A00, A00.0, J45.9',
      notes: 'Kategori: X## (tanpa desimal)\nSubkategori: X##.## (dengan desimal)',
    ),
    IcdClassification.icdMM: _ValidationRule(
      label: 'ICD-MM',
      pattern: r'^[A-Za-z]\d{2}(\.\d{0,2})?$',
      format: 'X##.##\nSama dengan format ICD-10\nContoh: O00, O00.1',
      notes: 'Kode khusus Maternal Mortality',
    ),
    IcdClassification.icdPM: _ValidationRule(
      label: 'ICD-PM',
      pattern: r'^[A-Za-z]\d{2}(\.\d{0,2})?$',
      format: 'X##.##\nSama dengan format ICD-10\nContoh: P00, P00.0',
      notes: 'Kode khusus Perinatal Mortality',
    ),
    IcdClassification.icdO: _ValidationRule(
      label: 'ICD-O',
      pattern: r'^([Cc]\d{2}\.\d|[Mm]\d{4}/\d)$',
      format: 'Topografi: C##.#\nMorfologi: M####/1 s.d M####/9\nContoh: C00.0, M8070/3',
      notes: 'Topografi diawali C (C00.0–C80.9)\nMorfologi diawali M (MXXXX/X)\nPerilaku: /0 jinak, /1 tidak pasti, /2 in situ, /3 ganas',
    ),
    IcdClassification.icd9CM: _ValidationRule(
      label: 'ICD-9-CM',
      pattern: r'^\d{3}(\.\d{1,2})?$',
      format: '###.##\n3 digit, opsional . + 1-2 digit\nContoh: 001, 001.0, 250.01',
      notes: 'Kategori: ### (tanpa desimal)\nSubkategori: ###.## (dengan desimal)',
    ),
  };

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    final rule = _rules[_selectedType]!;
    final results = <_ValidationResult>[];

    // 1. Format check
    final regex = RegExp(rule.pattern);
    final formatValid = regex.hasMatch(input);
    results.add(_ValidationResult(
      'Format kode', formatValid,
      formatValid ? 'Format sesuai aturan ${rule.label}' : 'Format tidak sesuai',
      formatValid ? 'Format: ${rule.format.replaceAll('\n', ', ')}' : null,
    ));

    if (formatValid) {
      // Additional structural checks
      if (_selectedType == IcdClassification.icdO) {
        if (input.startsWith('C') || input.startsWith('c')) {
          results.add(_ValidationResult(
            'Tipe', true,
            'Kode Topografi (Anatomi)',
          ));
        } else {
          final behavior = input.contains('/') ? input.split('/')[1] : '?';
          final behaviorMap = {
            '0': 'Jinak (Benign)',
            '1': 'Tidak pasti / keganasan rendah',
            '2': 'In situ',
            '3': 'Ganas (Malignant)',
            '6': 'Ganas metastasis',
            '9': 'Ganas, tidak pasti',
          };
          results.add(_ValidationResult(
            'Tipe', true,
            'Kode Morfologi (Histologi)',
          ));
          results.add(_ValidationResult(
            'Perilaku', behaviorMap.containsKey(behavior),
            behaviorMap[behavior] ?? 'Tidak dikenal',
            behaviorMap.containsKey(behavior) ? null : 'Digit / harus 0,1,2,3,6,9',
          ));
        }
      } else {
        final hasDecimal = input.contains('.');
        if (hasDecimal) {
          final decimalPart = input.split('.')[1];
          results.add(_ValidationResult(
            'Tingkat', true,
            'Subkategori (spesifik)',
          ));
          if (decimalPart.length > 2) {
            results.add(_ValidationResult(
              'Digit desimal', false,
              'Maksimal 2 digit setelah titik',
            ));
          }
        } else {
          results.add(_ValidationResult(
            'Tingkat', true,
            'Kategori (umum)',
          ));
        }
      }
    }

    // 2. Existence check
    try {
      final codes = await _service.load(_selectedType);
      final exists = codes.any((c) => c.code.toLowerCase() == input.toLowerCase());
      if (exists) {
        final match = codes.firstWhere((c) => c.code.toLowerCase() == input.toLowerCase());
        results.add(_ValidationResult(
          'Database', true,
          'Kode ditemukan!\n${match.description}',
        ));
      } else {
        results.add(_ValidationResult(
          'Database', false,
          'Kode tidak ditemukan dalam database ${_selectedType.label}',
          'Periksa ejaan atau cari kode serupa dengan format yang benar',
        ));
      }
    } catch (e) {
      results.add(_ValidationResult(
        'Database', false,
        'Gagal memuat database: $e',
      ));
    }

    if (mounted) setState(() { _results = results; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cek Validasi Kode'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/logo-app.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VALIDASI KODE ICD',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Periksa format dan ketersediaan\nkode ICD di database',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<IcdClassification>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'Klasifikasi',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: IcdClassification.values.map((t) {
              return DropdownMenuItem(value: t, child: Text(t.label));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() { _selectedType = v; _results = []; });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Masukkan kode ICD',
              hintText: 'Contoh: A00.0, M8070/3',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: 8),
          Text(
            _rules[_selectedType]!.format,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _validate,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? 'Memvalidasi...' : 'Validasi Kode'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 24),
            ..._results.map((r) => _resultTile(theme, color, r)),
          ],
        ],
      ),
    );
  }

  Widget _resultTile(ThemeData theme, Color color, _ValidationResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: r.valid
              ? Colors.green.withValues(alpha: 0.06)
              : Colors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: r.valid
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              r.valid ? Icons.check_circle : Icons.cancel,
              color: r.valid ? Colors.green : Colors.red,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: r.valid ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.message,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  if (r.hint != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationRule {
  final String label;
  final String pattern;
  final String format;
  final String notes;
  const _ValidationRule({
    required this.label,
    required this.pattern,
    required this.format,
    required this.notes,
  });
}

class _ValidationResult {
  final String label;
  final bool valid;
  final String message;
  final String? hint;
  const _ValidationResult(this.label, this.valid, this.message, [this.hint]);
}
