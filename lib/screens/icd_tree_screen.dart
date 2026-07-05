import 'package:flutter/material.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';
import 'detail_screen.dart';

class IcdTreeScreen extends StatefulWidget {
  const IcdTreeScreen({super.key});

  @override
  State<IcdTreeScreen> createState() => _IcdTreeScreenState();
}

class _IcdTreeScreenState extends State<IcdTreeScreen>
    with SingleTickerProviderStateMixin {
  final IcdService _service = IcdService();
  IcdClassification _selectedType = IcdClassification.icd10;
  Map<String, List<_PrefixGroup>> _tree = {};
  bool _loading = true;
  final Set<String> _expandedLetters = {};
  final Set<String> _expandedPrefixes = {};
  late AnimationController _shimmerController;

  static const _classIcons = <IcdClassification, IconData>{
    IcdClassification.icd10: Icons.medical_services_rounded,
    IcdClassification.icdMM: Icons.pregnant_woman_rounded,
    IcdClassification.icdPM: Icons.monitor_heart_rounded,
    IcdClassification.icdO: Icons.biotech_rounded,
    IcdClassification.icd9CM: Icons.healing_rounded,
  };

  static const _classDesc = <IcdClassification, String>{
    IcdClassification.icd10: 'Klasifikasi Penyakit Internasional Ed. 10',
    IcdClassification.icdMM: 'Kematian Ibu',
    IcdClassification.icdPM: 'Kematian Perinatal',
    IcdClassification.icdO: 'Onkologi Ed. 3',
    IcdClassification.icd9CM: 'Prosedur Klinis Ed. 9',
  };

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final codes = await _service.load(_selectedType);
    final tree = <String, List<_PrefixGroup>>{};
    final letters =
        codes.map((c) => c.code.substring(0, 1).toUpperCase()).toSet()
          ..remove('');
    for (final l in letters) {
      tree[l] = [];
    }
    for (final letter in tree.keys) {
      final prefixMap = <String, List<IcdCode>>{};
      for (final c
          in codes.where((c) => c.code.substring(0, 1).toUpperCase() == letter)) {
        final prefix = c.code.contains('.')
            ? c.code.substring(0, c.code.indexOf('.'))
            : (c.code.length > 3 ? c.code.substring(0, 3) : c.code);
        prefixMap.putIfAbsent(prefix, () => []);
        if (prefixMap[prefix]!.length < 50) {
          prefixMap[prefix]!.add(c);
        }
      }
      tree[letter] = prefixMap.entries
          .map((e) => _PrefixGroup(e.key, e.value))
          .toList()
        ..sort((a, b) => a.prefix.compareTo(b.prefix));
    }
    if (mounted) {
      setState(() {
        _tree = tree;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  int get _totalCodes =>
      _tree.values.fold(0, (sum, gs) => sum + gs.fold(0, (s, g) => s + g.codes.length));

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Pohon ICD',
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
          // ── Header Gradient ────────────────────────────────────────
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
                  'Jelajahi hierarki kode ICD',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Classification Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<IcdClassification>(
                      value: _selectedType,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      selectedItemBuilder: (_) => IcdClassification.values
                          .map((c) => Row(
                                children: [
                                  Icon(
                                    _classIcons[c] ?? Icons.list,
                                    color: color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    c.label,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                      items: IcdClassification.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(_classIcons[c] ?? Icons.list,
                                          color: color, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(c.label,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        Text(
                                          _classDesc[c] ?? '',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null && v != _selectedType) {
                          setState(() {
                            _selectedType = v;
                            _expandedLetters.clear();
                            _expandedPrefixes.clear();
                          });
                          _load();
                        }
                      },
                    ),
                  ),
                ),
                // Stats row
                if (!_loading) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statChip(Icons.folder_outlined, '${_tree.length} Kelompok'),
                      const SizedBox(width: 8),
                      _statChip(Icons.tag_rounded, '$_totalCodes Kode'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Tree List ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? _buildLoading(color)
                : _tree.isEmpty
                    ? _buildEmpty(color)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                        children:
                            (List<String>.from(_tree.keys)..sort()).map((letter) {
                          return _letterSection(theme, color, letter);
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLoading(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: color),
          const SizedBox(height: 16),
          Text(
            'Memuat data klasifikasi...',
            style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 64, color: color.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Tidak ada data',
              style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _letterSection(ThemeData theme, Color color, String letter) {
    final isExpanded = _expandedLetters.contains(letter);
    final groups = _tree[letter]!;
    final totalCodes = groups.fold(0, (s, g) => s + g.codes.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0.5,
        shadowColor: color.withValues(alpha: 0.1),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => isExpanded
                  ? _expandedLetters.remove(letter)
                  : _expandedLetters.add(letter)),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded
                        ? color.withValues(alpha: 0.25)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  color: isExpanded ? color.withValues(alpha: 0.04) : Colors.white,
                ),
                child: Row(
                  children: [
                    // Letter badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelompok $letter',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isExpanded
                                  ? color
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${groups.length} grup  ·  $totalCodes kode',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? color.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isExpanded
                              ? color
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: color.withValues(alpha: 0.2)),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Column(
                    children: groups
                        .asMap()
                        .entries
                        .map((e) => _prefixTile(
                            theme, color, e.value, e.key == groups.length - 1))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _prefixTile(
      ThemeData theme, Color color, _PrefixGroup group, bool isLast) {
    final isExpanded = _expandedPrefixes.contains(group.prefix);
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => isExpanded
              ? _expandedPrefixes.remove(group.prefix)
              : _expandedPrefixes.add(group.prefix)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isExpanded
                  ? color.withValues(alpha: 0.03)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                // Indent line
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? color.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Prefix badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? color.withValues(alpha: 0.12)
                        : color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isExpanded
                          ? color.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    group.prefix,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.codes.first.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isExpanded ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${group.codes.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            color: color.withValues(alpha: 0.02),
            child: Column(
              children: group.codes
                  .asMap()
                  .entries
                  .map((e) =>
                      _codeTile(theme, color, e.value, e.key == group.codes.length - 1))
                  .toList(),
            ),
          ),
        if (!isLast || isExpanded)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
      ],
    );
  }

  Widget _codeTile(ThemeData theme, Color color, IcdCode code, bool isLast) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => DetailScreen(code: code))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 9, 14, 9),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 28,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code.code,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                code.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _PrefixGroup {
  final String prefix;
  final List<IcdCode> codes;
  const _PrefixGroup(this.prefix, this.codes);
}
