import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  static const _pages = [
    _OnboardPage(
      'ICD-10',
      'Klasifikasi penyakit revisi ke-10 dari WHO',
      Icons.medical_services,
      'ICD-10 adalah standar internasional untuk mengklasifikasikan penyakit, gangguan, cedera, dan berbagai kondisi kesehatan lainnya.',
      '18.543',
    ),
    _OnboardPage(
      'ICD-MM',
      'Klasifikasi kematian ibu',
      Icons.pregnant_woman,
      'ICD-MM (Maternal Mortality) menyediakan kode khusus untuk penyebab kematian ibu terkait kehamilan, persalinan, dan masa nifas.',
      '4.777',
    ),
    _OnboardPage(
      'ICD-PM',
      'Klasifikasi kematian perinatal',
      Icons.child_care,
      'ICD-PM (Perinatal Mortality) digunakan untuk mengklasifikasikan kematian janin dan bayi baru lahir.',
      '838',
    ),
    _OnboardPage(
      'ICD-O',
      'Klasifikasi onkologi',
      Icons.health_and_safety,
      'ICD-O (Oncology) mengklasifikasikan neoplasma berdasarkan morfologi dan topografi, digunakan dalam registri kanker.',
      '4.217',
    ),
    _OnboardPage(
      'ICD-9-CM',
      'Modifikasi klinis ICD revisi ke-9',
      Icons.healing,
      'ICD-9-CM adalah versi modifikasi untuk penggunaan klinis dengan kode rinci untuk diagnosis dan prosedur medis.',
      '4.626',
    ),
    _OnboardPage(
      'Cari & Filter',
      'Temukan kode dengan cepat',
      Icons.search,
      'Cari kode ICD berdasarkan kode, deskripsi, atau chapter. Filter realtime menampilkan hasil instan dari ribuan kode yang tersedia.',
      null,
    ),
    _OnboardPage(
      'Detail Lengkap',
      'Informasi diagnosis menyeluruh',
      Icons.description,
      'Setiap kode dilengkapi informasi lengkap: kode, deskripsi, chapter, dan klasifikasi. Cocok untuk referensi diagnosis dan penelitian.',
      null,
    ),
    _OnboardPage(
      'Siap Digunakan',
      'Semua ICD dalam satu aplikasi',
      Icons.check_circle,
      'Akses 5 klasifikasi ICD offline, pencarian cepat, dan informasi lengkap — kapan saja, di mana saja.',
      null,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 56),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) {
                      final page = _pages[i];
                      final isFeatureSlide = i >= 5 && i < _pages.length - 1;
                      final isFinalSlide = i == _pages.length - 1;

                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          double scale = 1.0;
                          double opacity = 1.0;
                          if (_controller.position.haveDimensions) {
                            final pos = _controller.page ?? i.toDouble();
                            final diff = (pos - i).abs();
                            scale = 1.0 - (diff * 0.08).clamp(0, 0.15);
                            opacity = 1.0 - (diff * 0.3).clamp(0, 0.5);
                          }
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Card(
                            elevation: 2,
                            shadowColor: theme.shadowColor.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isFinalSlide) ...[
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        page.icon,
                                        size: isFeatureSlide ? 44 : 52,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      page.name,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      page.desc,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (i < 5) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${page.codeCount!} entri',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      page.details,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Icon(
                                        page.icon,
                                        size: 80,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      page.name,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      page.desc,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      page.details,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _FeatureBadge(
                                          icon: Icons.offline_bolt,
                                          label: 'Offline',
                                          theme: theme,
                                        ),
                                        _FeatureBadge(
                                          icon: Icons.search,
                                          label: 'Cepat',
                                          theme: theme,
                                        ),
                                        _FeatureBadge(
                                          icon: Icons.storage,
                                          label: '5 Klasifikasi',
                                          theme: theme,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _currentPage == i
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (isLast) {
                              _goToHome();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isLast ? 'Mulai' : 'Selanjutnya'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIDA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Mobile ICD Database Application',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 8,
              child: TextButton(
                onPressed: () => _goToHome(),
                child: const Text('Lewati'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToHome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _OnboardPage {
  final String name;
  final String desc;
  final IconData icon;
  final String details;
  final String? codeCount;
  const _OnboardPage(this.name, this.desc, this.icon, this.details, this.codeCount);
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
