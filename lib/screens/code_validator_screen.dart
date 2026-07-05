import 'package:flutter/material.dart';
import '../services/icd_service.dart';

class CodeValidatorScreen extends StatefulWidget {
  const CodeValidatorScreen({super.key});

  @override
  State<CodeValidatorScreen> createState() => _CodeValidatorScreenState();
}

class _CodeValidatorScreenState extends State<CodeValidatorScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final IcdService _service = IcdService();
  IcdClassification _selectedType = IcdClassification.icd10;
  bool _isLoading = false;
  List<_ValidationResult> _results = [];
  bool _hasValidated = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _classIcons = <IcdClassification, IconData>{
    IcdClassification.icd10: Icons.medical_services_rounded,
    IcdClassification.icdMM: Icons.pregnant_woman_rounded,
    IcdClassification.icdPM: Icons.monitor_heart_rounded,
    IcdClassification.icdO: Icons.biotech_rounded,
    IcdClassification.icd9CM: Icons.healing_rounded,
  };

  static final Map<IcdClassification, _ValidationRule> _rules = {
    IcdClassification.icd10: _ValidationRule(
      label: 'ICD-10',
      pattern: r'^[A-Za-z]\d{2}(\.\d{0,2})?$',
      format: 'X##.##\n1 huruf + 2 digit, opsional . + 1-2 digit',
      example: 'A00, A00.0, J45.9',
      notes: 'Kategori: X## (tanpa desimal)\nSubkategori: X##.## (dengan desimal)',
    ),
    IcdClassification.icdMM: _ValidationRule(
      label: 'ICD-MM',
      pattern: r'^[A-Za-z]\d{2}(\.\d{0,2})?$',
      format: 'X##.##\nSama dengan format ICD-10',
      example: 'O00, O00.1',
      notes: 'Kode khusus Maternal Mortality',
    ),
    IcdClassification.icdPM: _ValidationRule(
      label: 'ICD-PM',
      pattern: r'^[A-Za-z]\d{2}(\.\d{0,2})?$',
      format: 'X##.##\nSama dengan format ICD-10',
      example: 'P00, P00.0',
      notes: 'Kode khusus Perinatal Mortality',
    ),
    IcdClassification.icdO: _ValidationRule(
      label: 'ICD-O',
      pattern: r'^([Cc]\d{2}\.\d|[Mm]\d{4}/\d)$',
      format: 'Topografi: C##.#\nMorfologi: M####/1 s.d M####/9',
      example: 'C00.0, M8070/3',
      notes: 'Topografi diawali C (C00.0–C80.9)\nMorfologi diawali M (MXXXX/X)\nPerilaku: /0 jinak, /1 tidak pasti, /2 in situ, /3 ganas',
    ),
    IcdClassification.icd9CM: _ValidationRule(
      label: 'ICD-9-CM',
      pattern: r'^\d{3}(\.\d{1,2})?$',
      format: '###.##\n3 digit, opsional . + 1-2 digit',
      example: '001, 001.0, 250.01',
      notes: 'Kategori: ### (tanpa desimal)\nSubkategori: ###.## (dengan desimal)',
    ),
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _results = [];
      _hasValidated = true;
    });
    _animController.reset();

    final rule = _rules[_selectedType]!;
    final results = <_ValidationResult>[];

    // 1. Format check
    final regex = RegExp(rule.pattern);
    final formatValid = regex.hasMatch(input);
    results.add(_ValidationResult(
      'Format Struktur', formatValid,
      formatValid ? 'Sesuai dengan aturan penulisan ${rule.label}' : 'Format tidak sesuai standar',
      hint: formatValid ? 'Struktur: ${rule.format.replaceAll('\n', ' - ')}' : 'Harus mengikuti format: ${rule.example}',
    ));

    if (formatValid) {
      // Additional structural checks
      if (_selectedType == IcdClassification.icdO) {
        if (input.startsWith('C') || input.startsWith('c')) {
          results.add(const _ValidationResult(
            'Tipe Kode', true,
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
          results.add(const _ValidationResult(
            'Tipe Kode', true,
            'Kode Morfologi (Histologi)',
          ));
          results.add(_ValidationResult(
            'Perilaku Neoplasma', behaviorMap.containsKey(behavior),
            behaviorMap[behavior] ?? 'Kode perilaku tidak valid',
            hint: behaviorMap.containsKey(behavior) ? null : 'Digit setelah garis miring (/) harus 0,1,2,3,6,9',
          ));
        }
      } else {
        final hasDecimal = input.contains('.');
        if (hasDecimal) {
          final decimalPart = input.split('.')[1];
          results.add(const _ValidationResult(
            'Level Spesifisitas', true,
            'Subkategori (Sangat Spesifik)',
          ));
          if (decimalPart.length > 2) {
            results.add(const _ValidationResult(
              'Batas Digit', false,
              'Terlalu banyak digit desimal',
              hint: 'Maksimal 2 digit setelah tanda titik',
            ));
          }
        } else {
          results.add(const _ValidationResult(
            'Level Spesifisitas', true,
            'Kategori (Umum / Global)',
          ));
        }
      }
    }

    // 2. Database existence check
    try {
      final codes = await _service.load(_selectedType);
      final exists = codes.any((c) => c.code.toLowerCase() == input.toLowerCase());
      if (exists) {
        final match = codes.firstWhere((c) => c.code.toLowerCase() == input.toLowerCase());
        results.add(_ValidationResult(
          'Validasi Database', true,
          'Kode Ditemukan & Valid',
          hint: match.description,
          isPrimary: true,
        ));
      } else {
        results.add(_ValidationResult(
          'Validasi Database', false,
          'Kode Tidak Ditemukan',
          hint: 'Kode dengan format ini tidak tercatat dalam database resmi ${_selectedType.label}.',
          isPrimary: true,
        ));
      }
    } catch (e) {
      results.add(_ValidationResult(
        'Database Server', false,
        'Gagal memuat data referensi',
        hint: e.toString(),
      ));
    }

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Cek Validasi Kode',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo-app.png',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih klasifikasi dan masukkan kode untuk memvalidasi format serta eksistensinya.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  
                  // Classification Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<IcdClassification>(
                        value: _selectedType,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
                        items: IcdClassification.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_classIcons[c] ?? Icons.list, color: color, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(c.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null && v != _selectedType) {
                            setState(() {
                              _selectedType = v;
                              _hasValidated = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Code Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _codeController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Cth: ${_rules[_selectedType]!.example.split(",").first.trim()}',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, letterSpacing: 0),
                        prefixIcon: Icon(Icons.pin_rounded, color: color),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _validate(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Validate Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _validate,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Validasi Kode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Results Area ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverToBoxAdapter(
              child: _isLoading
                  ? const SizedBox() // Handled by button loading state
                  : !_hasValidated
                      ? _buildGuideCard(theme, color)
                      : _buildResultsList(theme, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(ThemeData theme, Color color) {
    final rule = _rules[_selectedType]!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Aturan Format ${rule.label}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _guideRow(Icons.format_shapes_rounded, 'Struktur', rule.format),
          const SizedBox(height: 12),
          _guideRow(Icons.lightbulb_outline_rounded, 'Contoh', rule.example),
          const SizedBox(height: 12),
          _guideRow(Icons.description_outlined, 'Catatan', rule.notes),
        ],
      ),
    );
  }

  Widget _guideRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(ThemeData theme, Color color) {
    if (_results.isEmpty) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HASIL VALIDASI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ..._results.map((r) => _resultCard(theme, color, r)),
        ],
      ),
    );
  }

  Widget _resultCard(ThemeData theme, Color color, _ValidationResult r) {
    final bool isSuccess = r.valid;
    final Color statusColor = isSuccess ? const Color(0xFF00897B) : const Color(0xFFE53935);
    final Color bgColor = isSuccess ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.isPrimary 
              ? statusColor.withValues(alpha: 0.5) 
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: r.isPrimary ? 2 : 1,
        ),
        boxShadow: r.isPrimary
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (r.hint != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.hint!,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationRule {
  final String label;
  final String pattern;
  final String format;
  final String example;
  final String notes;
  const _ValidationRule({
    required this.label,
    required this.pattern,
    required this.format,
    required this.example,
    required this.notes,
  });
}

class _ValidationResult {
  final String label;
  final bool valid;
  final String message;
  final String? hint;
  final bool isPrimary;
  const _ValidationResult(
    this.label,
    this.valid,
    this.message, {
    this.hint,
    this.isPrimary = false,
  });
}
