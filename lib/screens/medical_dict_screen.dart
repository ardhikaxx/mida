import 'dart:async';
import 'package:flutter/material.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';
import 'detail_screen.dart';

class MedicalDictScreen extends StatefulWidget {
  const MedicalDictScreen({super.key});

  @override
  State<MedicalDictScreen> createState() => _MedicalDictScreenState();
}

class _MedicalDictScreenState extends State<MedicalDictScreen>
    with SingleTickerProviderStateMixin {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_DictEntry> _results = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _classifications = [
    IcdClassification.icd10,
    IcdClassification.icdMM,
    IcdClassification.icdPM,
    IcdClassification.icdO,
    IcdClassification.icd9CM,
  ];

  static const _termInfo = <String, String>{
    'anasarca': 'Edema berat yang menyeluruh (seluruh tubuh)',
    'ascites': 'Penumpukan cairan di rongga perut',
    'benign': 'Jinak, tidak bersifat kanker',
    'carcinoma': 'Kanker yang berasal dari jaringan epitel',
    'congenital': 'Bawaan lahir, sudah ada sejak lahir',
    'deficiency': 'Kekurangan atau defisiensi',
    'dilatation': 'Pelebaran suatu struktur atau organ',
    'disease': 'Penyakit',
    'disorder': 'Gangguan atau kelainan',
    'dysfunction': 'Gangguan fungsi',
    'edema': 'Pembengkakan akibat penumpukan cairan',
    'embolism': 'Sumbatan pembuluh darah oleh embolus',
    'failure': 'Kegagalan fungsi organ',
    'fracture': 'Patah tulang',
    'gangrene': 'Kematian jaringan akibat kekurangan aliran darah',
    'hemorrhage': 'Perdarahan',
    'hernia': 'Penonjolan organ melalui dinding rongga',
    'hypertension': 'Tekanan darah tinggi',
    'hypertrophy': 'Pembesaran akibat penebalan jaringan',
    'infection': 'Infeksi oleh mikroorganisme',
    'inflammation': 'Peradangan',
    'injury': 'Cedera atau luka',
    'insufficiency': 'Ketidakcukupan fungsi',
    'lesion': 'Kelainan pada jaringan',
    'malignant': 'Ganas, bersifat kanker',
    'malformation': 'Kelainan bentuk bawaan',
    'malnutrition': 'Kurang gizi',
    'neoplasm': 'Pertumbuhan jaringan baru abnormal (tumor)',
    'obstruction': 'Penyumbatan',
    'perforation': 'Robekan atau lubang pada dinding organ',
    'pneumonia': 'Radang paru-paru',
    'poisoning': 'Keracunan',
    'prolapse': 'Turunnya organ dari posisi normal',
    'rupture': 'Pecahnya suatu organ atau pembuluh',
    'sepsis': 'Infeksi berat yang menyebar ke seluruh tubuh',
    'stenosis': 'Penyempitan pembuluh atau saluran',
    'syndrome': 'Kumpulan gejala yang membentuk suatu pola',
    'thrombosis': 'Pembentukan bekuan darah dalam pembuluh',
    'tumor': 'Benjolan atau massa jaringan abnormal',
    'ulcer': 'Luka terbuka pada jaringan',
  };

  // Popular quick search terms
  static const _popularTerms = [
    'Hypertension', 'Infection', 'Fracture',
    'Pneumonia', 'Tumor', 'Sepsis',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    final all = <_DictEntry>[];

    // Check built-in glossary first
    for (final e in _termInfo.entries) {
      if (e.key.contains(q) || q.contains(e.key)) {
        all.add(_DictEntry(e.key, e.value, null, null, isGlossary: true));
      }
    }

    // Search ICD codes
    for (final cls in _classifications) {
      try {
        final codes = await _service.load(cls);
        for (final c in codes) {
          final descLower = c.description.toLowerCase();
          if (descLower.contains(q)) {
            all.add(_DictEntry(c.code, c.description, c, cls.label));
            if (all.length >= 31) break;
          }
        }
      } catch (_) {}
      if (all.length >= 31) break;
    }

    if (mounted) {
      setState(() {
        _results = all.take(30).toList();
        _loading = false;
        _searched = true;
      });
      if (all.isNotEmpty) _animController.forward(from: 0);
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
            Icon(Icons.menu_book_rounded, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text(
              'Glosarium Medis',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
      body: Column(
        children: [
          // ── Hero Search Header ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari istilah medis & kode ICD terkait',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Cth: infection, fracture, tumor...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: color),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _results = [];
                                  _searched = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                    onChanged: (v) {
                      setState(() {});
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 300),
                        () => _search(v),
                      );
                    },
                  ),
                ),
                // Popular terms chips
                if (!_searched && _controller.text.isEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _popularTerms
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    _controller.text = t;
                                    _search(t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? _buildLoading(color)
                : !_searched
                    ? _buildEmptyState(theme, color)
                    : _results.isEmpty
                        ? _buildNotFound(theme)
                        : _buildResults(theme, color),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: color),
          const SizedBox(height: 16),
          Text(
            'Mencari di glosarium & database ICD...',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book_rounded,
                size: 48, color: color.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 20),
          Text(
            'Glosarium Istilah Medis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cari istilah medis dalam Bahasa Inggris untuk mendapatkan definisi dan kode ICD terkait',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          // Glossary preview cards
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Istilah Populer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._termInfo.entries.take(5).map((e) => _glossaryPreviewCard(theme, color, e.key, e.value)),
        ],
      ),
    );
  }

  Widget _glossaryPreviewCard(ThemeData theme, Color color, String term, String def) {
    return GestureDetector(
      onTap: () {
        _controller.text = term;
        _search(term);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  term[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  Text(
                    def,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil ditemukan',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba gunakan istilah medis dalam Bahasa Inggris',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, Color color) {
    final glossaryEntries = _results.where((r) => r.isGlossary).toList();
    final icdEntries = _results.where((r) => !r.isGlossary).toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Results count
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  '${_results.length} hasil ditemukan',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Glossary Definition Section ─────────────────────────
          if (glossaryEntries.isNotEmpty) ...[
            _sectionLabel(theme, color, Icons.auto_stories_rounded, 'Definisi Istilah'),
            const SizedBox(height: 8),
            ...glossaryEntries.map((r) => _glossaryCard(theme, color, r)),
            const SizedBox(height: 16),
          ],

          // ── ICD Code Results Section ───────────────────────────
          if (icdEntries.isNotEmpty) ...[
            _sectionLabel(theme, color, Icons.medical_services_rounded, 'Kode ICD Terkait'),
            const SizedBox(height: 8),
            ...icdEntries.map((r) => _icdCard(theme, color, r)),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, Color color, IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _glossaryCard(ThemeData theme, Color color, _DictEntry r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                r.term[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.term,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Glosarium',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _icdCard(ThemeData theme, Color color, _DictEntry r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0.5,
        shadowColor: color.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: r.codeData != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(code: r.codeData!)),
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code badge
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    r.term,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      if (r.classification != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.classification!,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: theme.colorScheme.outline.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DictEntry {
  final String term;
  final String description;
  final IcdCode? codeData;
  final String? classification;
  final bool isGlossary;

  const _DictEntry(
    this.term,
    this.description,
    this.codeData,
    this.classification, {
    this.isGlossary = false,
  });
}
