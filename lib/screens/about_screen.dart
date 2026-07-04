import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: const Text('Tentang MIDA'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _heroSection(theme, color),
          const SizedBox(height: 24),
          _donasiSection(theme, color),
          const SizedBox(height: 24),
          _sumberDataSection(theme, color),
          const SizedBox(height: 24),
          _pengembangSection(theme, color),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required ThemeData theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _heroSection(ThemeData theme, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Image.asset('assets/images/logo-kemkes-new.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24, child: Image.asset('assets/images/logo-kemenkes.png', fit: BoxFit.contain)),
              const SizedBox(width: 16),
              SizedBox(height: 24, child: Image.asset('assets/images/bangga-melayani-bangsa-seeklogo.png', fit: BoxFit.contain)),
              const SizedBox(width: 16),
              SizedBox(height: 24, child: Image.asset('assets/images/logo-berakhlak.png', fit: BoxFit.contain)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'MIDA',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mobile ICD Database Application',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Versi 1.0.0',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi pencarian kode ICD offline untuk tenaga kesehatan dan mahasiswa kedokteran. Mendukung 5 klasifikasi: ICD-10, ICD-MM, ICD-PM, ICD-O, dan ICD-9-CM.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _donasiSection(ThemeData theme, Color color) {
    return _sectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Donasi',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dukung pengembangan aplikasi ini melalui QRIS:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Image.asset('assets/images/qris.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumberDataSection(ThemeData theme, Color color) {
    final sources = [
      ('ICD-10', 'World Health Organization', Icons.health_and_safety),
      ('ICD-MM', 'WHO — Maternal Mortality', Icons.pregnant_woman),
      ('ICD-PM', 'WHO — Perinatal Mortality', Icons.monitor_heart),
      ('ICD-O', 'WHO — Oncology, 3rd Ed.', Icons.biotech),
      ('ICD-9-CM', 'WHO — Clinical Modification', Icons.healing),
    ];
    return _sectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.source, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sumber Data',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sources.map((s) => _sourceItem(theme, color, s.$1, s.$2, s.$3)),
        ],
      ),
    );
  }

  Widget _sourceItem(ThemeData theme, Color color, String name, String source, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  source,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pengembangSection(ThemeData theme, Color color) {
    return _sectionCard(
      theme: theme,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_outline, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengembang',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Yanuar Ardhika Rahmadhani Ubaidillah',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
