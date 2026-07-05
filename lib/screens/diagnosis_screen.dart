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

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_DiagResult> _results = [];
  List<_DiagResult> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  bool _searched = false;

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

          if (score > 0) {
            all.add(_DiagResult(c, cls.label, score));
          }
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
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
        title: const Text('Diagnosis → ICD'),
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ketik diagnosis untuk mendapatkan kode ICD yang sesuai:',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cth: demam, batuk, hipertensi...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                    filled: true,
                    fillColor: color.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 200), () => _search(v, suggestions: true));
                  },
                  onSubmitted: (v) => _search(v),
                ),
              ],
            ),
          ),
          if (_focusNode.hasFocus && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length + 1,
                separatorBuilder: (_, _) => Divider(height: 1, indent: 12, endIndent: 12, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text('Saran teratas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                    );
                  }
                  final r = _suggestions[i - 1];
                  return InkWell(
                    onTap: () {
                      _controller.text = r.code.code;
                      _search(r.code.code);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(r.code.code, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 11, letterSpacing: 1)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.code.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                Text(r.classification, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.trending_up, size: 14, color: r.score >= 70 ? Colors.green : theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text('${r.score}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: r.score >= 70 ? Colors.green : theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                  );
                },
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
                            Icon(Icons.healing_outlined, size: 64, color: color.withValues(alpha: 0.15)),
                            const SizedBox(height: 16),
                            Text('Ketik diagnosis untuk mendapatkan\nkode ICD yang sesuai', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text('Tidak ditemukan hasil', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                            itemCount: _results.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                  child: Text('${_results.length} hasil dari ${_classifications.length} klasifikasi', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                                );
                              }
                              final r = _results[i - 1];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Material(
                                  borderRadius: BorderRadius.circular(14),
                                  elevation: 0.5,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(code: r.code))),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border(left: BorderSide(color: color, width: 3)),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(minWidth: 68),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(r.code.code, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 11, letterSpacing: 1)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(r.code.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                                                      child: Text(r.classification, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(Icons.trending_up, size: 12, color: r.score >= 80 ? Colors.green : theme.colorScheme.outline),
                                                    Text(' ${r.score}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: r.score >= 80 ? Colors.green : theme.colorScheme.outline)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
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
