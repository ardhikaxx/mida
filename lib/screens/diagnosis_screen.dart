import 'dart:async';
import 'package:flutter/material.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';
import 'detail_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with SingleTickerProviderStateMixin {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<_DiagResult> _results = [];
  List<_DiagResult> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  bool _searched = false;
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
    'demam': ['fever', 'pyrexia', 'febrile'],
    'batuk': ['cough', 'tussis'],
    'nyeri': ['pain', 'ache', 'sore', 'tender', 'algia'],
    'sakit': ['pain', 'ache', 'sore'],
    'sesak': ['dyspnea', 'shortness', 'breathless'],
    'pusing': ['dizziness', 'vertigo', 'syncope'],
    'kepala': ['head', 'cranial', 'headache'],
    'mual': ['nausea', 'vomiting', 'emesis'],
    'diare': ['diarrhea', 'diarrhoea'],
    'ruam': ['rash', 'eruption', 'urticaria'],
    'bengkak': ['swelling', 'edema', 'inflammation'],
    'lemah': ['weakness', 'fatigue', 'asthenia', 'malaise'],
    'infeksi': ['infection', 'sepsis', 'abscess'],
    'luka': ['wound', 'injury', 'trauma', 'laceration'],
    'radang': ['itis', 'inflammation'],
    'tumor': ['tumor', 'neoplasm', 'cancer', 'carcinoma'],
    'kehamilan': ['pregnancy', 'pregnant', 'obstetric', 'maternal'],
    'bayi': ['infant', 'neonatal', 'newborn', 'perinatal'],
    'alergi': ['allergy', 'allergic', 'hypersensitivity'],
    'darah': ['blood', 'hemorrhage', 'bleeding'],
    'jantung': ['heart', 'cardiac', 'cardiovascular', 'myocardi'],
    'paru': ['lung', 'pulmonary', 'respirat', 'bronch'],
    'kencing': ['urinary', 'urination', 'dysuria'],
    'mata': ['eye', 'ocular', 'ophthalmi', 'vision'],
    'kulit': ['skin', 'dermat', 'rash'],
    'tulang': ['bone', 'fracture', 'skeletal', 'osteo'],
    'otak': ['brain', 'cerebral', 'neurolog', 'nerve'],
    'lambung': ['stomach', 'gastr', 'ulcer'],
    'usus': ['intestine', 'colon', 'bowel'],
    'hati': ['hepat', 'liver'],
  };

  // Quick example chips
  static const _quickExamples = [
    'Demam', 'Batuk', 'Hipertensi', 'Diabetes', 'Fraktur', 'Asma',
  ];

  Set<String> _expandTerms(String q) {
    final terms = <String>{q};
    final words = q.split(RegExp(r'\s+'));
    for (final w in words) {
      terms.add(w);
      if (_idEnMap.containsKey(w)) terms.addAll(_idEnMap[w]!);
    }
    return terms;
  }

  Future<void> _search(String query, {bool suggestions = false}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _suggestions = [];
        _searched = false;
      });
      return;
    }

    setState(() => _loading = true);
    final terms = _expandTerms(q);
    final all = <_DiagResult>[];

    for (final cls in _classifications) {
      try {
        final codes = await _service.load(cls);
        for (final c in codes) {
          final cl = c.code.toLowerCase();
          final dl = c.description.toLowerCase();
          int score = 0;

          for (final t in terms) {
            if (cl == t) { score = 100; break; }
            if (cl.startsWith(t)) { score = 85; break; }
            if (cl.contains(t)) { score = 65; break; }
            if (dl.contains(t)) {
              final idx = dl.indexOf(t);
              score = (50 - (idx / dl.length * 20).round()).clamp(10, 50);
              break;
            }
          }

          if (score > 0) all.add(_DiagResult(c, cls.label, score));
        }
      } catch (_) {}
    }

    all.sort((a, b) => b.score.compareTo(a.score));
    final seen = <String>{};
    final deduped = <_DiagResult>[];
    for (final r in all) {
      if (seen.add('${r.code.code}|${r.classification}')) {
        deduped.add(r);
        if (suggestions && deduped.length >= 7) break;
        if (!suggestions && deduped.length >= 30) break;
      }
    }

    if (mounted) {
      setState(() {
        if (suggestions) {
          _suggestions = deduped;
        } else {
          _results = deduped;
          _searched = true;
          _suggestions = [];
          _focusNode.unfocus();
        }
        _loading = false;
      });
      if (!suggestions && deduped.isNotEmpty) {
        _animController.forward(from: 0);
      }
    }
  }

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
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
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
            Text(
              'Diagnosis',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
            SizedBox(width: 6),
            Text(
              'ICD',
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
                  'Temukan kode ICD dari diagnosis',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                // Search Bar
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
                    autofocus: true,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Cth: demam, batuk, hipertensi...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: color),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _results = [];
                                  _suggestions = [];
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                    onChanged: (v) {
                      setState(() {}); // update clear button
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 200),
                        () => _search(v, suggestions: true),
                      );
                    },
                    onSubmitted: (v) => _search(v),
                  ),
                ),
                // Quick example chips
                if (!_searched && _controller.text.isEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickExamples.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _controller.text = e;
                            _search(e);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Suggestion Dropdown ─────────────────────────────────────
          if (_focusNode.hasFocus && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          'Saran Teratas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 6),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                      itemBuilder: (_, i) {
                        final r = _suggestions[i];
                        return InkWell(
                          onTap: () {
                            _controller.text = r.code.code;
                            _search(r.code.code);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r.code.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.code.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        r.classification,
                                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _scoreColor(r.score).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${r.score}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _scoreColor(r.score),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ── Body ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: color),
                        const SizedBox(height: 16),
                        Text(
                          'Mencari dari semua klasifikasi...',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  )
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

  Widget _buildEmptyState(ThemeData theme, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medical_information_outlined, size: 48, color: color.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              'Cari Kode ICD dari Diagnosis',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketikkan nama diagnosis atau gejala dalam Bahasa Indonesia maupun Inggris',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _infoBadge(theme, color, Icons.translate_rounded, '5 Klasifikasi ICD'),
                _infoBadge(theme, color, Icons.offline_bolt_rounded, 'Offline'),
                _infoBadge(theme, color, Icons.language_rounded, 'ID + EN'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(ThemeData theme, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
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
            'Coba gunakan kata kunci yang berbeda',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, Color color) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _results.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_results.length} hasil dari ${_classifications.length} klasifikasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final r = _results[i - 1];
          final scoreColor = _scoreColor(r.score);
          final isTopResult = i == 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: isTopResult ? 2 : 0.5,
              shadowColor: color.withValues(alpha: 0.15),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(code: r.code)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isTopResult
                          ? color.withValues(alpha: 0.3)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                            constraints: const BoxConstraints(minWidth: 72),
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
                          if (isTopResult) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
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
                      // Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.code.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
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
                                // Relevance bar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Relevansi',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                                          backgroundColor: scoreColor.withValues(alpha: 0.12),
                                          valueColor: AlwaysStoppedAnimation(scoreColor),
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
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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

class _DiagResult {
  final IcdCode code;
  final String classification;
  final int score;
  const _DiagResult(this.code, this.classification, this.score);
}
