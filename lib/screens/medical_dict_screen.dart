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

class _MedicalDictScreenState extends State<MedicalDictScreen> {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  List<_DictEntry> _results = [];
  bool _loading = false;
  Timer? _debounce;

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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final all = <_DictEntry>[];
    final definition = _termInfo.entries.firstWhere(
      (e) => e.key == q,
      orElse: () => MapEntry('', ''),
    ).value;
    if (definition.isNotEmpty) {
      all.add(_DictEntry(q, definition, null, null));
    }
    for (final cls in _classifications) {
      try {
        final codes = await _service.load(cls);
        for (final c in codes) {
          final descLower = c.description.toLowerCase();
          if (descLower.contains(q)) {
            all.add(_DictEntry(c.code, c.description, c, cls.label));
            if (all.length >= 30) break;
          }
        }
      } catch (_) {}
      if (all.length >= 30) break;
    }
    if (mounted) {
      setState(() {
        _results = all.take(30).toList();
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
        title: const Text('Glosarium Medis'),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: color.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cari istilah medis beserta kode ICD terkait:',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Cari istilah...',
                    prefixIcon: const Icon(Icons.menu_book),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _results = []);
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
                    _debounce = Timer(const Duration(milliseconds: 300), () => _search(v));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 64, color: color.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('Cari istilah untuk memulai', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          if (r.codeData == null) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info, color: color, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.term, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                                        const SizedBox(height: 4),
                                        Text(r.description, style: TextStyle(height: 1.4, fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              borderRadius: BorderRadius.circular(12),
                              elevation: 0.5,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: r.codeData != null
                                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(code: r.codeData!)))
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(left: BorderSide(color: color, width: 3)),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 60),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(r.term, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 11)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r.description, style: const TextStyle(fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            if (r.classification != null) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(r.classification!, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
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

class _DictEntry {
  final String term;
  final String description;
  final IcdCode? codeData;
  final String? classification;
  const _DictEntry(this.term, this.description, this.codeData, this.classification);
}
