import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';

class DetailScreen extends StatefulWidget {
  final IcdCode code;

  const DetailScreen({super.key, required this.code});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final IcdService _service = IcdService();
  List<IcdCode> _allCodes = [];
  String get _prefix => widget.code.code.contains('.')
      ? widget.code.code.substring(0, widget.code.code.indexOf('.'))
      : widget.code.code;

  List<IcdCode> get _similarCodes {
    final prefix = _prefix;
    return _allCodes
        .where((c) => c.code != widget.code.code && c.code.startsWith(prefix))
        .take(5)
        .toList();
  }

  IcdCode? get _parentCategory {
    final prefix = _prefix;
    return _allCodes.cast<IcdCode?>().firstWhere(
      (c) => c!.code == prefix,
      orElse: () => null,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final type = IcdClassification.fromLabel(widget.code.classification);
      final codes = await _service.load(type);
      if (mounted) setState(() => _allCodes = codes);
    } catch (_) {}
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
        title: Text(widget.code.classification),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _heroSection(context, theme, color),
          const SizedBox(height: 20),
          _descriptionSection(theme, color),
          const SizedBox(height: 20),
          if (_allCodes.isNotEmpty) ...[
            _hierarchySection(theme, color),
            const SizedBox(height: 20),
            if (_similarCodes.isNotEmpty) ...[
              _similarSection(theme, color),
              const SizedBox(height: 20),
            ],
          ],
          _infoSection(theme, color),
        ],
      ),
    );
  }

  Widget _heroSection(BuildContext context, ThemeData theme, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(
            'KODE ICD',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.code.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.code.code} disalin'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.code.code,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.copy_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionSection(ThemeData theme, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Deskripsi',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.code.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _hierarchySection(ThemeData theme, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hierarki',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _hierarchyItem(theme, color, 'Chapter ${widget.code.chapter}', widget.code.chapterTitle ?? '', Icons.folder_outlined, Colors.orange),
          _hierarchyConnector(theme),
          _hierarchyItem(theme, color, _parentCategory?.code ?? _prefix, _parentCategory?.description ?? 'Kategori', Icons.label_outline, Colors.blue),
          _hierarchyConnector(theme),
          _hierarchyItem(theme, color, widget.code.code, widget.code.description, Icons.code, color),
        ],
      ),
    );
  }

  Widget _hierarchyItem(ThemeData theme, Color color, String title, String subtitle, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hierarchyConnector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: SizedBox(
        height: 20,
        child: CustomPaint(
          painter: _ConnectorPainter(theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _similarSection(ThemeData theme, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kode Serupa',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _similarCodes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = _similarCodes[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailScreen(code: s)),
                  ),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            s.description,
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _infoSection(ThemeData theme, Color color) {
    final items = <_InfoItem>[
      if (widget.code.chapter != null)
        _InfoItem(
          Icons.folder_outlined,
          'Chapter',
          widget.code.chapter == 'Morphology' || widget.code.chapter == 'Topography'
              ? widget.code.chapter!
              : 'Chapter ${widget.code.chapter}',
        ),
      if (widget.code.chapterTitle != null)
        _InfoItem(
          Icons.label_outline,
          'Kategori',
          widget.code.chapterTitle!,
        ),
      _InfoItem(
        Icons.category_outlined,
        'Klasifikasi',
        widget.code.classification,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informasi',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((e) => _infoTile(theme, color, e)),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme, Color color, _InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  _ConnectorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
