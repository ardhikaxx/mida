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
    for (final cls in _classifications) {
      try {
        final codes = await _service.load(cls);
        for (final c in codes) {
          int score = 0;
          final codeLower = c.code.toLowerCase();
          final descLower = c.description.toLowerCase();

          if (codeLower == q) {
            score = 100;
          } else if (codeLower.startsWith(q)) {
            score = 80;
          } else if (codeLower.contains(q)) {
            score = 60;
          } else if (descLower.contains(q)) {
            final idx = descLower.indexOf(q);
            score = 50 - (idx / descLower.length * 20).round();
          }

          if (score > 0) {
            all.add(_SearchResult(c, cls.label, score));
          }
        }
      } catch (_) {}
    }

    all.sort((a, b) => b.score.compareTo(a.score));
    if (mounted) {
      setState(() {
        _results = all.take(20).toList();
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
