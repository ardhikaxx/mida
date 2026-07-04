import 'package:flutter/material.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardPage(
      'ICD-10',
      'Klasifikasi penyakit revisi ke-10 dari WHO',
      Icons.medical_services,
      'ICD-10 adalah standar internasional untuk mengklasifikasikan penyakit, gangguan, cedera, dan berbagai kondisi kesehatan lainnya. Digunakan secara global untuk diagnosis, penelitian, dan pelaporan kesehatan.',
    ),
    _OnboardPage(
      'ICD-MM',
      'Klasifikasi kematian ibu',
      Icons.pregnant_woman,
      'ICD-MM (Maternal Mortality) menyediakan kode khusus untuk mengidentifikasi dan mengklasifikasikan penyebab kematian ibu terkait kehamilan, persalinan, dan masa nifas. Penting untuk pemantauan kesehatan ibu.',
    ),
    _OnboardPage(
      'ICD-PM',
      'Klasifikasi kematian perinatal',
      Icons.child_care,
      'ICD-PM (Perinatal Mortality) digunakan untuk mengklasifikasikan kematian janin dan bayi baru lahir. Membantu dalam analisis penyebab kematian perinatal untuk meningkatkan perawatan ibu dan bayi.',
    ),
    _OnboardPage(
      'ICD-O',
      'Klasifikasi onkologi',
      Icons.health_and_safety,
      'ICD-O (Oncology) mengklasifikasikan neoplasma berdasarkan morfologi (jenis sel tumor) dan topografi (lokasi anatomi). Digunakan dalam registri kanker dan penelitian onkologi.',
    ),
    _OnboardPage(
      'ICD-9-CM',
      'Modifikasi klinis ICD revisi ke-9',
      Icons.healing,
      'ICD-9-CM adalah versi modifikasi dari ICD-9 yang dikembangkan untuk penggunaan klinis di Amerika Serikat. Mencakup kode yang lebih rinci untuk diagnosis dan prosedur medis.',
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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MIDA',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            page.icon,
                            size: 64,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          page.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.desc,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
                      ],
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
                    children: [
                      ...List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        );
                      }),
                      const SizedBox(width: 24),
                      TextButton(
                        onPressed: () => _goToHome(context),
                        child: Text(
                          isLast ? '' : 'Lewati',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (isLast) {
                          _goToHome(context);
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
      ),
    );
  }

  void _goToHome(BuildContext context) {
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
  const _OnboardPage(this.name, this.desc, this.icon, this.details);
}
