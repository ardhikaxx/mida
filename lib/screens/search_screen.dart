import 'package:flutter/material.dart';
import '../models/icd_code.dart';
import '../services/icd_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final IcdClassification type;
  final Color color;

  const SearchScreen({super.key, required this.type, required this.color});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final IcdService _service = IcdService();
  final TextEditingController _controller = TextEditingController();
  List<IcdCode> _allCodes = [];
  bool _loading = true;
  bool _showAll = false;
  String _query = '';
  static const int _initialLimit = 100;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final codes = await _service.load(widget.type);
    setState(() {
      _allCodes = codes;
      _loading = false;
    });
  }

  List<IcdCode> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allCodes;
    return _allCodes.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          (c.chapter?.toLowerCase().contains(q) ?? false) ||
          (c.chapterTitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  bool get _isSearching => _query.trim().isNotEmpty;
  List<IcdCode> get _displayList =>
      _showAll || _isSearching ? _filtered : _filtered.take(_initialLimit).toList();
  int get _hiddenCount => _filtered.length - _initialLimit;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: widget.color.withValues(alpha: 0.05),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Cari kode atau nama ${widget.type.label}...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
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
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: _displayList.length + (_showMoreVisible ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_showMoreVisible && i == _displayList.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _showAll = true),
                            icon: const Icon(Icons.expand_more),
                            label: Text('Lihat semua ($_hiddenCount lainnya)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.color,
                              side: BorderSide(color: widget.color.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final item = _displayList[i];
                    return _IcdCard(item: item, color: widget.color, theme: theme);
                  },
                ),
        ),
      ],
    );
  }

  bool get _showMoreVisible => !_isSearching && !_showAll && _hiddenCount > 0;
}

class _IcdCard extends StatelessWidget {
  final IcdCode item;
  final Color color;
  final ThemeData theme;

  const _IcdCard({
    required this.item,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(code: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.code,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 13,
                    letterSpacing: 1.2,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.chapter != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.chapter == 'Morphology' || item.chapter == 'Topography'
                              ? item.chapter!
                              : 'Chapter ${item.chapter}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
