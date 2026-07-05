import 'package:flutter/material.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';
import 'detail_screen.dart';

class IcdTreeScreen extends StatefulWidget {
  const IcdTreeScreen({super.key});

  @override
  State<IcdTreeScreen> createState() => _IcdTreeScreenState();
}

class _IcdTreeScreenState extends State<IcdTreeScreen> {
  final IcdService _service = IcdService();
  IcdClassification _selectedType = IcdClassification.icd10;
  Map<String, List<_PrefixGroup>> _tree = {};
  bool _loading = true;
  final Set<String> _expandedLetters = {};
  final Set<String> _expandedPrefixes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final codes = await _service.load(_selectedType);
    final tree = <String, List<_PrefixGroup>>{};
    final letters = codes.map((c) => c.code.substring(0, 1).toUpperCase()).toSet()..remove('');
    for (final l in letters) {
      tree[l] = [];
    }
    for (final letter in tree.keys) {
      final prefixMap = <String, List<IcdCode>>{};
      for (final c in codes.where((c) => c.code.substring(0, 1).toUpperCase() == letter)) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_selectedType.label),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Klasifikasi',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<IcdClassification>(
                  value: _selectedType,
                  isDense: true,
                  isExpanded: true,
                  items: IcdClassification.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 32),
                    children: (List<String>.from(_tree.keys)..sort()).map((letter) {
                      final isExpanded = _expandedLetters.contains(letter);
                      final groups = _tree[letter]!;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedLetters.remove(letter);
                                } else {
                                  _expandedLetters.add(letter);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isExpanded ? color.withValues(alpha: 0.08) : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(letter, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Kode $letter',
                                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text('${groups.length} grup', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                  const SizedBox(width: 6),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded)
                            ...groups.map((g) => _prefixTile(theme, color, g)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _prefixTile(ThemeData theme, Color color, _PrefixGroup group) {
    final isExpanded = _expandedPrefixes.contains(group.prefix);
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPrefixes.remove(group.prefix);
                } else {
                  _expandedPrefixes.add(group.prefix);
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isExpanded ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(group.prefix, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.codes.first.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Text('${group.codes.length}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 18, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ...group.codes.map((c) => _codeTile(theme, color, c)),
        ],
      ),
    );
  }

  Widget _codeTile(ThemeData theme, Color color, IcdCode code) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(code: code))),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(code.code, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 11, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  code.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.outline),
            ],
          ),
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
