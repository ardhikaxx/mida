import 'package:flutter/material.dart';
import '../services/icd_service.dart';

class CodingGuidelinesScreen extends StatefulWidget {
  final IcdClassification? initialType;
  const CodingGuidelinesScreen({super.key, this.initialType});

  @override
  State<CodingGuidelinesScreen> createState() => _CodingGuidelinesScreenState();
}

class _CodingGuidelinesScreenState extends State<CodingGuidelinesScreen> {
  late IcdClassification _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? IcdClassification.icd10;
  }

  static final Map<IcdClassification, _GuidelineData> _guidelines = {
    IcdClassification.icd10: _GuidelineData(
      label: 'ICD-10',
      icon: Icons.medical_services_outlined,
      description: 'International Statistical Classification of Diseases and Related Health Problems, 10th Revision. Standar internasional untuk klasifikasi diagnosis dan prosedur medis.',
      generalRules: [
        'Kode ICD-10 terdiri dari 1 huruf diikuti 2 digit (kategori), opsional desimal untuk subkategori',
        'Kode kategori: A00–Z99 (huruf kapital + 2 digit)',
        'Kode subkategori: kategori + titik + 1-2 digit (contoh: A00.0, J45.9)',
        'Huruf U dicadangkan untuk kode sementara/provisional (U00–U99)',
        'Setiap entitas hanya boleh diberi satu kode yang paling spesifik',
      ],
      combinationRules: [
        'Kode kombinasi digunakan untuk menyatakan 2 kondisi dalam satu kode',
        'Contoh: E10.2 = Diabetes melitus tipe 1 dengan komplikasi ginjal',
        'Jika ada kode kombinasi, gunakan kode tersebut, jangan memisah',
      ],
      notes: [
        'Excludes1: kondisi yang tidak boleh dikode bersamaan (mutually exclusive)',
        'Excludes2: kondisi yang terpisah namun boleh dikode bersamaan jika ada',
        'Includes: daftar kondisi yang termasuk dalam kode tersebut',
        'Code first: kode kondisi mendasar harus diberikan terlebih dahulu',
        'Use additional code: gunakan kode tambahan untuk detail spesifik',
      ],
      chapters: [
        _ChapterInfo('A00–B99', 'Penyakit Infeksi dan Parasitik'),
        _ChapterInfo('C00–D48', 'Neoplasma'),
        _ChapterInfo('D50–D89', 'Penyakit Darah & Imunitas'),
        _ChapterInfo('E00–E90', 'Penyakit Endokrin, Nutrisi & Metabolik'),
        _ChapterInfo('F00–F99', 'Gangguan Mental & Perilaku'),
        _ChapterInfo('G00–G99', 'Penyakit Sistem Saraf'),
        _ChapterInfo('H00–H59', 'Penyakit Mata & Adneksa'),
        _ChapterInfo('H60–H95', 'Penyakit Telinga & Mastoid'),
        _ChapterInfo('I00–I99', 'Penyakit Sistem Sirkulasi'),
        _ChapterInfo('J00–J99', 'Penyakit Sistem Pernapasan'),
        _ChapterInfo('K00–K93', 'Penyakit Sistem Pencernaan'),
        _ChapterInfo('L00–L99', 'Penyakit Kulit & Jaringan Subkutan'),
        _ChapterInfo('M00–M99', 'Penyakit Muskuloskeletal & Jaringan Ikat'),
        _ChapterInfo('N00–N99', 'Penyakit Sistem Genitourinaria'),
        _ChapterInfo('O00–O99', 'Kehamilan, Persalinan & Nifas'),
        _ChapterInfo('P00–P96', 'Kondisi Perinatal'),
        _ChapterInfo('Q00–Q99', 'Kelainan Kongenital & Kromosom'),
        _ChapterInfo('R00–R99', 'Gejala, Tanda & Temuan Abnormal'),
        _ChapterInfo('S00–T98', 'Cedera, Keracunan & Akibat Eksternal'),
        _ChapterInfo('V01–Y98', 'Penyebab Eksternal Morbiditas & Mortalitas'),
        _ChapterInfo('Z00–Z99', 'Faktor yang Mempengaruhi Status Kesehatan'),
      ],
    ),
    IcdClassification.icdMM: _GuidelineData(
      label: 'ICD-MM',
      icon: Icons.pregnant_woman_outlined,
      description: 'ICD-Maternal Mortality. Klasifikasi khusus untuk kematian maternal terkait kehamilan, persalinan, dan nifas.',
      generalRules: [
        'ICD-MM adalah adaptasi dari ICD-10 Chapter O (O00–O99)',
        'Digunakan untuk mengklasifikasikan penyebab kematian maternal',
        'Kode terdiri dari 1 huruf (O) + 2 digit + opsional desimal',
        'Kode O00–O08: Kehamilan dengan abortus',
        'Kode O10–O16: Edema, proteinuria & hipertensi pada kehamilan',
        'Kode O20–O29: Penyakit lain pada kehamilan',
        'Kode O30–O48: Penanganan ibu terkait janin & cairan ketuban',
        'Kode O60–O77: Komplikasi persalinan & kelahiran',
        'Kode O85–O92: Komplikasi nifas',
        'Kode O94–O99: Kondisi lain pada masa nifas',
      ],
      combinationRules: [
        'Kode O00–O08 mencakup berbagai tipe abortus dengan komplikasi',
        'Kode O10–O16 untuk hipertensi mencakup pre-eklampsia dan eklampsia',
      ],
      notes: [
        'Kematian maternal: kematian selama kehamilan atau dalam 42 hari setelah terminasi',
        'Kode O98–O99 untuk penyakit ibu yang memperumit kehamilan',
        'Gunakan kode tambahan untuk penyebab obstetrik langsung/tidak langsung',
      ],
      chapters: [
        _ChapterInfo('O00–O08', 'Kehamilan dengan abortus'),
        _ChapterInfo('O10–O16', 'Hipertensi pada kehamilan'),
        _ChapterInfo('O20–O29', 'Penyakit lain pada kehamilan'),
        _ChapterInfo('O30–O48', 'Penanganan ibu terkait janin'),
        _ChapterInfo('O60–O77', 'Komplikasi persalinan'),
        _ChapterInfo('O85–O92', 'Komplikasi nifas'),
        _ChapterInfo('O94–O99', 'Kondisi lain pada nifas'),
      ],
    ),
    IcdClassification.icdPM: _GuidelineData(
      label: 'ICD-PM',
      icon: Icons.monitor_heart_outlined,
      description: 'ICD-Perinatal Mortality. Klasifikasi untuk kematian janin dan neonatal (periode perinatal).',
      generalRules: [
        'ICD-PM adalah adaptasi dari ICD-10 Chapter P (P00–P96)',
        'Digunakan untuk mengklasifikasikan penyebab kematian perinatal',
        'Kode terdiri dari 1 huruf (P) + 2 digit + opsional desimal',
        'P00–P04: Janin terpapar faktor risiko ibu',
        'P05–P08: Gangguan terkait usia kehamilan & pertumbuhan janin',
        'P10–P15: Trauma lahir',
        'P20–P29: Gangguan pernapasan & kardiovaskular perinatal',
        'P35–P39: Infeksi spesifik perinatal',
        'P50–P61: Gangguan perdarahan & hematologi perinatal',
        'P70–P74: Gangguan endokrin & metabolik perinatal',
        'P75–P78: Gangguan pencernaan perinatal',
        'P80–P83: Kondisi kulit & termoregulasi perinatal',
        'P90–P96: Gangguan perinatal lainnya',
      ],
      combinationRules: [
        'Kode kombinasi untuk berat lahir dan usia kehamilan',
        'Gunakan kode tambahan untuk penyebab kematian yang mendasar',
      ],
      notes: [
        'Periode perinatal: mulai 22 minggu kehamilan hingga 7 hari setelah lahir',
        'Kematian janin: lahir tanpa tanda kehidupan (stillbirth)',
        'Kematian neonatal: kematian dalam 28 hari pertama kehidupan',
        'Gunakan P95 untuk kematian janin tanpa sebab',
      ],
      chapters: [
        _ChapterInfo('P00–P04', 'Faktor risiko ibu pada janin'),
        _ChapterInfo('P05–P08', 'Gangguan pertumbuhan janin'),
        _ChapterInfo('P10–P15', 'Trauma lahir'),
        _ChapterInfo('P20–P29', 'Gangguan pernapasan perinatal'),
        _ChapterInfo('P35–P39', 'Infeksi perinatal'),
        _ChapterInfo('P50–P61', 'Gangguan perdarahan perinatal'),
        _ChapterInfo('P70–P74', 'Gangguan endokrin perinatal'),
        _ChapterInfo('P75–P78', 'Gangguan pencernaan perinatal'),
        _ChapterInfo('P80–P83', 'Kondisi kulit perinatal'),
        _ChapterInfo('P90–P96', 'Gangguan perinatal lainnya'),
      ],
    ),
    IcdClassification.icdO: _GuidelineData(
      label: 'ICD-O',
      icon: Icons.health_and_safety_outlined,
      description: 'International Classification of Diseases for Oncology. Klasifikasi khusus untuk tumor/neoplasma dengan kode topografi (anatomi) dan morfologi (histologi).',
      generalRules: [
        'ICD-O memiliki 2 sumbu: Topografi (C##.#) dan Morfologi (M####/#)',
        'Kode Topografi: C00.0 – C80.9 menunjukkan lokasi anatomis tumor',
        'Kode Morfologi: M####/# menunjukkan tipe sel dan perilaku tumor',
        'Digit terakhir morfologi menunjukkan perilaku (behavior):',
        '  /0 = Jinak (Benign)',
        '  /1 = Tidak pasti / keganasan rendah',
        '  /2 = In situ (belum invasif)',
        '  /3 = Ganas (Malignant)',
        '  /6 = Ganas metastasis',
        '  /9 = Ganas, tidak pasti',
        'Huruf C pada topografi = "Cancer" bukan chapter ICD-10',
      ],
      combinationRules: [
        'Kode lengkap = Topografi + Morfologi (contoh: C50.4 + M8500/3 = Karsinoma duktal payudara)',
        'Untuk neoplasma ganas, gunakan kode ICD-10 C00–C97 sebagai tambahan',
        'Behavior /6 digunakan untuk metastasis (lokasi sekunder)',
      ],
      notes: [
        'Topografi C80.9 = Unknown primary site',
        'Morfologi M8000/0 = Neoplasma tidak terdefinisi, jinak',
        'Morfologi M8000/3 = Neoplasma tidak terdefinisi, ganas',
        'M8070/3 = Squamous cell carcinoma (tipe paling umum)',
        'Gunakan panduan histologi untuk menentukan kode morfologi yang tepat',
      ],
      chapters: [
        _ChapterInfo('C00–C14', 'Bibir, Rongga Mulut & Faring'),
        _ChapterInfo('C15–C26', 'Sistem Pencernaan'),
        _ChapterInfo('C30–C39', 'Sistem Pernapasan'),
        _ChapterInfo('C40–C41', 'Tulang, Sendi & Kartilago'),
        _ChapterInfo('C42–C42', 'Sistem Hematopoietik & Retikuloendotelial'),
        _ChapterInfo('C43–C44', 'Kulit'),
        _ChapterInfo('C45–C49', 'Jaringan Lunak & Retroperitoneum'),
        _ChapterInfo('C50–C50', 'Payudara'),
        _ChapterInfo('C51–C58', 'Organ Genital Wanita'),
        _ChapterInfo('C60–C63', 'Organ Genital Pria'),
        _ChapterInfo('C64–C68', 'Saluran Kemih'),
        _ChapterInfo('C69–C72', 'Mata, Otak & Sistem Saraf'),
        _ChapterInfo('C73–C75', 'Kelenjar Endokrin'),
        _ChapterInfo('C76–C76', 'Lain-lain & Tidak Spesifik'),
        _ChapterInfo('C77–C77', 'Kelenjar Limfe'),
        _ChapterInfo('C80–C80', 'Unknown Primary Site'),
        _ChapterInfo('M8000–M9580', 'Neoplasma Epitel'),
        _ChapterInfo('M9590–M9989', 'Neoplasma Jaringan Limfoid & Hematopoietik'),
        _ChapterInfo('M8800–M9371', 'Neoplasma Jaringan Lunak & Tulang'),
        _ChapterInfo('M9380–M9580', 'Neoplasma Sistem Saraf'),
        _ChapterInfo('M9590–M9989', 'Leukemia, Limfoma & Neoplasma Hematologi'),
      ],
    ),
    IcdClassification.icd9CM: _GuidelineData(
      label: 'ICD-9-CM',
      icon: Icons.healing_outlined,
      description: 'International Classification of Diseases, 9th Revision, Clinical Modification. Sistem klasifikasi diagnosis dan prosedur dengan digit tambahan untuk spesifikasi klinis.',
      generalRules: [
        'ICD-9-CM terdiri dari 3–5 digit numerik',
        '3 digit = kode kategori',
        '4 digit = subkategori (spesifik)',
        '5 digit = subclassification (sangat spesifik)',
        'Kode ICD-9-CM murni numerik tanpa huruf',
        'Desimal ditempatkan setelah 3 digit pertama',
        'Contoh: 250.01 = Diabetes melitus tipe 1, tidak terkontrol',
      ],
      combinationRules: [
        'ICD-9-CM memiliki banyak kode kombinasi (satu kode untuk 2 kondisi)',
        'Contoh: 250.xx untuk diabetes dengan berbagai komplikasi tergantung digit ke-5',
        'Digit ke-5 sering menunjukkan spesifikasi seperti: 0 = tidak terkontrol, 1 = terkontrol',
      ],
      notes: [
        'V-code (V01–V91): Faktor yang mempengaruhi status kesehatan (analog ICD-10 Z00–Z99)',
        'E-code (E000–E999): Penyebab cedera/keracunan eksternal',
        'Gunakan kode spesifik: jika tersedia 5 digit, jangan hanya gunakan 3 digit',
        'ICD-9-CM masih digunakan untuk sistem klaim dan reimbursement di beberapa negara',
        'Kode prosedur ICD-9-CM: 00–99 (2 digit) + 2 digit tambahan',
      ],
      chapters: [
        _ChapterInfo('001–139', 'Penyakit Infeksi & Parasitik'),
        _ChapterInfo('140–239', 'Neoplasma'),
        _ChapterInfo('240–279', 'Penyakit Endokrin, Nutrisi & Metabolik'),
        _ChapterInfo('280–289', 'Penyakit Darah & Organ Pembentuk Darah'),
        _ChapterInfo('290–319', 'Gangguan Mental'),
        _ChapterInfo('320–389', 'Penyakit Sistem Saraf & Organ Indera'),
        _ChapterInfo('390–459', 'Penyakit Sistem Sirkulasi'),
        _ChapterInfo('460–519', 'Penyakit Sistem Pernapasan'),
        _ChapterInfo('520–579', 'Penyakit Sistem Pencernaan'),
        _ChapterInfo('580–629', 'Penyakit Sistem Genitourinaria'),
        _ChapterInfo('630–679', 'Kehamilan, Persalinan & Nifas'),
        _ChapterInfo('680–709', 'Penyakit Kulit & Jaringan Subkutan'),
        _ChapterInfo('710–739', 'Penyakit Muskuloskeletal & Jaringan Ikat'),
        _ChapterInfo('740–759', 'Kelainan Kongenital'),
        _ChapterInfo('760–779', 'Kondisi Perinatal'),
        _ChapterInfo('780–799', 'Gejala, Tanda & Temuan Abnormal'),
        _ChapterInfo('800–999', 'Cedera & Keracunan'),
        _ChapterInfo('V01–V91', 'Faktor Kesehatan (V-code)'),
        _ChapterInfo('E000–E999', 'Penyebab Eksternal (E-code)'),
      ],
    ),
  };

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
        title: const Text('Panduan Pengkodean'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildHeader(theme, color),
          const SizedBox(height: 16),
          _buildPicker(theme, color),
          const SizedBox(height: 16),
          _buildDescription(theme, color),
          const SizedBox(height: 16),
          _buildSection(theme, color, 'Aturan Umum', Icons.rule_outlined, _data.generalRules),
          const SizedBox(height: 12),
          if (_data.combinationRules.isNotEmpty)
            _buildSection(theme, color, 'Kode Kombinasi', Icons.merge_type, _data.combinationRules),
          if (_data.combinationRules.isNotEmpty) const SizedBox(height: 12),
          _buildSection(theme, color, 'Catatan Penting', Icons.warning_amber_outlined, _data.notes),
          const SizedBox(height: 12),
          _buildChapterList(theme, color),
        ],
      ),
    );
  }

  _GuidelineData get _data => _guidelines[_selectedType]!;

  Widget _buildHeader(ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(_data.icon, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANDUAN PENGKODEAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _data.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IcdClassification>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: IcdClassification.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  Icon(_guidelines[t]!.icon, size: 20, color: color),
                  const SizedBox(width: 10),
                  Text(t.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedType = v);
          },
        ),
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _data.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, Color color, String title, IconData icon, List<String> items) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Expanded(child: Text(item, style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChapterList(ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'Daftar Chapter',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._data.chapters.map((ch) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ch.range,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ch.title,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _GuidelineData {
  final String label;
  final IconData icon;
  final String description;
  final List<String> generalRules;
  final List<String> combinationRules;
  final List<String> notes;
  final List<_ChapterInfo> chapters;
  const _GuidelineData({
    required this.label,
    required this.icon,
    required this.description,
    required this.generalRules,
    required this.combinationRules,
    required this.notes,
    required this.chapters,
  });
}

class _ChapterInfo {
  final String range;
  final String title;
  const _ChapterInfo(this.range, this.title);
}
