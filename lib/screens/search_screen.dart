import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _debounce;
  String? _selectedChapter;
  List<String> _chapters = [];
  static const int _initialLimit = 100;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final codes = await _service.load(widget.type);
    final chapters = codes.map((c) => c.chapter).whereType<String>().toSet().toList()..sort();
    setState(() {
      _allCodes = codes;
      _chapters = chapters;
      _loading = false;
    });
  }

  List<IcdCode> get _filtered {
    var result = _allCodes;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((c) {
        return c.code.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            (c.chapter?.toLowerCase().contains(q) ?? false) ||
            (c.chapterTitle?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (_selectedChapter != null) {
      result = result.where((c) => c.chapter == _selectedChapter).toList();
    }
    return result;
  }

  bool get _isSearching => _query.trim().isNotEmpty;
  List<IcdCode> get _displayList =>
      _showAll || _isSearching ? _filtered : _filtered.take(_initialLimit).toList();
  int get _hiddenCount => _filtered.length - _initialLimit;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: widget.color.withValues(alpha: 0.05),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLogo('assets/images/logo-kemenkes.png'),
                  _buildLogo('assets/images/bangga-melayani-bangsa-seeklogo.png'),
                  _buildLogo('assets/images/logo-berakhlak.png', height: 48),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Cari kode atau nama ${widget.type.label}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _debounce?.cancel();
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
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => _query = v);
                  });
                },
              ),
            ],
          ),
        ),
        if (!_loading && _chapters.length > 1)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: Text(
                    'Semua',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedChapter == null ? Colors.white : null,
                    ),
                  ),
                  selected: _selectedChapter == null,
                  onSelected: (_) => setState(() => _selectedChapter = null),
                  visualDensity: VisualDensity.compact,
                  selectedColor: widget.color,
                  checkmarkColor: Colors.white,
                ),
                const SizedBox(width: 6),
                ..._chapters.map((ch) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      ch == 'Morphology' || ch == 'Topography' ? ch : 'Ch. $ch',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedChapter == ch ? Colors.white : null,
                      ),
                    ),
                    selected: _selectedChapter == ch,
                    onSelected: (sel) => setState(() => _selectedChapter = sel ? ch : null),
                    visualDensity: VisualDensity.compact,
                    selectedColor: widget.color,
                    checkmarkColor: Colors.white,
                  ),
                )),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, MediaQuery.of(context).padding.bottom + 60),
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

  Widget _buildLogo(String path, {double height = 32}) {
    return SizedBox(
      height: height,
      child: Image.asset(path, fit: BoxFit.contain),
    );
  }
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

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: item.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.code} disalin'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        elevation: 1.5,
        shadowColor: color.withValues(alpha: 0.15),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(code: item)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _copyCode(context),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 68),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.code,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: color,
                          fontSize: 12,
                          letterSpacing: 1,
                          height: 1.3,
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
                          item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.chapter != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
