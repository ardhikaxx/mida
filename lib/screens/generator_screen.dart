import 'dart:async';
import 'package:flutter/material.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';
import 'detail_screen.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with SingleTickerProviderStateMixin {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_SearchResult> _results = [];
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

  static const _idEnMap = <String, List<String>>{
    'demam': ['fever', 'pyrexia', 'hyperthermia', 'febrile'],
    'batuk': ['cough', 'tussis', 'whooping'],
    'nyeri': ['pain', 'ache', 'sore', 'tender', 'hurt', 'algia'],
    'sakit': ['pain', 'ache', 'sore', 'tender', 'hurt'],
    'sesak': ['dyspnea', 'shortness', 'breathless', 'respiratory distress'],
    'pusing': ['dizziness', 'vertigo', 'syncope', 'lightheaded'],
    'kepala': ['head', 'cranial', 'cephalgia', 'headache'],
    'mual': ['nausea', 'vomiting', 'emesis', 'regurgitation'],
    'diare': ['diarrhea', 'diarrhoea', 'loose stool'],
    'ruam': ['rash', 'eruption', 'exanthem', 'urticaria', 'hives'],
    'bengkak': ['swelling', 'edema', 'oedema', 'inflammation', 'tumor', 'mass'],
    'lemah': ['weakness', 'fatigue', 'asthenia', 'malaise', 'lethargy'],
    'berdarah': ['hemorrhage', 'bleeding', 'blood loss'],
    'infeksi': ['infection', 'sepsis', 'abscess', 'contagious'],
    'luka': ['wound', 'injury', 'trauma', 'laceration', 'lesion'],
    'batu': ['stone', 'calculus', 'lithiasis'],
    'radang': ['itis', 'inflammation', 'inflammatory'],
    'tumor': ['tumor', 'tumour', 'neoplasm', 'cancer', 'carcinoma', 'malignant', 'benign'],
    'lumpuh': ['paralysis', 'palsy', 'paresis', 'paralytic'],
    'buta': ['blindness', 'blind', 'vision loss'],
    'tuli': ['deafness', 'hearing loss'],
    'sulit': ['difficulty', 'disturbance', 'disorder', 'dysfunction'],
    'turun': ['prolapse', 'descent', 'ptosis'],
    'benda': ['foreign body', 'object'],
    'keracunan': ['poisoning', 'intoxication', 'toxic'],
    'alergi': ['allergy', 'allergic', 'hypersensitivity'],
    'kehamilan': ['pregnancy', 'pregnant', 'obstetric', 'maternal'],
    'bayi': ['infant', 'neonatal', 'newborn', 'perinatal'],
    'kencing': ['urinary', 'urination', 'micturition', 'dysuria'],
    'buang': ['defecation', 'bowel', 'stool', 'feces', 'faeces'],
  };

  // Categorized symptom chips
  static const _symptomCategories = [
    (
      'Umum',
      Icons.thermostat_rounded,
      Color(0xFF00897B),
      ['demam', 'lemah', 'pusing', 'mual']
    ),
    (
      'Pernapasan',
      Icons.air_rounded,
      Color(0xFF1E88E5),
      ['sesak', 'batuk']
    ),
    (
      'Nyeri',
      Icons.healing_rounded,
      Color(0xFFE53935),
      ['nyeri', 'sakit kepala']
    ),
    (
      'Pencernaan',
      Icons.restaurant_rounded,
      Color(0xFFFF8F00),
      ['diare', 'buang']
    ),
    (
      'Kulit',
      Icons.face_rounded,
      Color(0xFF8E24AA),
      ['ruam', 'bengkak']
    ),
  ];

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
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = true;
    });
    _focusNode.unfocus();

    final all = <_SearchResult>[];
    final words = q.split(RegExp(r'\s+'));
    final searchTerms = <String>{q};
    for (final w in words) {
      searchTerms.add(w);
      if (_idEnMap.containsKey(w)) searchTerms.addAll(_idEnMap[w]!);
    }

    for (final cls in _classifications) {
      try {
        final codes = await _service.load(cls);
        for (final c in codes) {
          final codeLower = c.code.toLowerCase();
          final descLower = c.description.toLowerCase();

          for (final term in searchTerms) {
            int score = 0;
            if (codeLower == term) {
              score = 100;
            } else if (codeLower.startsWith(term)) {
              score = 85;
            } else if (codeLower.contains(term)) {
              score = 65;
            } else if (descLower.contains(term)) {
              final idx = descLower.indexOf(term);
              score = (50 - (idx / descLower.length * 20).round()).clamp(10, 50);
            }
            if (score > 0) {
              all.add(_SearchResult(c, cls.label, score));
              break;
            }
          }
        }
      } catch (_) {}
    }

    all.sort((a, b) => b.score.compareTo(a.score));
    final seen = <String>{};
    final deduped = <_SearchResult>[];
    for (final r in all) {
      if (seen.add('${r.code.code}|${r.classification}')) {
        deduped.add(r);
      }
    }

    if (mounted) {
      setState(() {
        _results = deduped.take(20).toList();
        _loading = false;
      });
      if (deduped.isNotEmpty) _animController.forward(from: 0);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF00897B);
    if (score >= 50) return const Color(0xFFFF8F00);
    return const Color(0xFF78909C);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Tinggi';
    if (score >= 50) return 'Sedang';
    return 'Rendah';
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
            Icon(Icons.manage_search_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Cari Berdasarkan Gejala',
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
                  'Masukkan gejala untuk mendapatkan kode ICD',
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
                      hintText: 'Cth: demam batuk, nyeri dada...',
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
                        const Duration(milliseconds: 500),
                        () => _search(v),
                      );
                    },
                    onSubmitted: (v) => _search(v),
                  ),
                ),
                // Quick symptom chips per category
                if (!_searched) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final cat in _symptomCategories)
                          for (final s in cat.$4)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  _controller.text = s;
                                  _search(s);
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat.$2,
                                          size: 12, color: Colors.white.withValues(alpha: 0.85)),
                                      const SizedBox(width: 5),
                                      Text(
                                        s,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
            'Mencari kode ICD dari gejala...',
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
            child: Icon(Icons.medication_rounded,
                size: 48, color: color.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 20),
          Text(
            'Cari ICD dari Gejala',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketikkan satu atau beberapa gejala dalam Bahasa Indonesia atau Inggris untuk mendapatkan kode ICD yang sesuai',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          // Category grid
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kategori Gejala',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: _symptomCategories.map((cat) {
              return GestureDetector(
                onTap: () {
                  _controller.text = cat.$4.first;
                  _search(cat.$4.first);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: cat.$3.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: cat.$3.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: cat.$3.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.$2, size: 16, color: cat.$3),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cat.$1,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: cat.$3,
                              ),
                            ),
                            Text(
                              cat.$4.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
            'Coba masukkan gejala yang berbeda\natau kombinasikan beberapa gejala',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, Color color) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 32),
        itemCount: _results.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_results.length} hasil dari ${_classifications.length} klasifikasi',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }
          final r = _results[i - 1];
          final isTop = i == 1;
          final scoreColor = _scoreColor(r.score);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: isTop ? 2 : 0.5,
              shadowColor: color.withValues(alpha: 0.12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailScreen(code: r.code)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isTop
                          ? color.withValues(alpha: 0.3)
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Code badge
                      Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(minWidth: 68),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              r.code.code,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (isTop) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TOP',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF8F00),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.code.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r.classification,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Relevansi',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _scoreLabel(r.score),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: scoreColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: r.score / 100,
                                          minHeight: 4,
                                          backgroundColor: scoreColor
                                              .withValues(alpha: 0.12),
                                          valueColor:
                                              AlwaysStoppedAnimation(scoreColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchResult {
  final IcdCode code;
  final String classification;
  final int score;
  const _SearchResult(this.code, this.classification, this.score);
}
