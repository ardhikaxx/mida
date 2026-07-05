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

class _GeneratorScreenState extends State<GeneratorScreen> {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  List<_SearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = true;
    });

    final all = <_SearchResult>[];
    final words = q.split(RegExp(r'\s+'));
    final searchTerms = <String>{q};
    for (final w in words) {
      searchTerms.add(w);
      if (_idEnMap.containsKey(w)) {
        searchTerms.addAll(_idEnMap[w]!);
      }
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
    }
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
        title: const Text('Cari Berdasarkan Gejala'),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: color.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan gejala atau kata kunci untuk mencari kode ICD yang sesuai:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Contoh: demam, batuk, nyeri dada...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _results = [];
                                _searched = false;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () => _search(v));
                  },
                  onSubmitted: (v) => _search(v),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ['demam', 'batuk', 'nyeri', 'sesak', 'pusing', 'mual', 'sakit kepala', 'diare', 'ruam', 'bengkak'].map((s) {
                    return ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        _controller.text = s;
                        _search(s);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.healing_outlined, size: 64, color: color.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('Masukkan gejala untuk memulai', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text('Tidak ditemukan hasil', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(12, 4, 12, MediaQuery.of(context).padding.bottom + 32),
                            itemCount: _results.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                  child: Text(
                                    '${_results.length} hasil ditemukan dari ${_classifications.length} klasifikasi',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                );
                              }
                              final r = _results[i - 1];
                              return _resultCard(context, theme, color, r);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, ThemeData theme, Color color, _SearchResult r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        elevation: 0.5,
        shadowColor: color.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(code: r.code))),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: color, width: 3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.code.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 11, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.code.description,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(r.classification, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.trending_up, size: 12, color: r.score >= 80 ? Colors.green : theme.colorScheme.outline),
                          const SizedBox(width: 2),
                          Text('${r.score}%', style: TextStyle(fontSize: 10, color: r.score >= 80 ? Colors.green : theme.colorScheme.outline, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
