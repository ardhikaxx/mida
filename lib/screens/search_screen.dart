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
  int get _hiddenCount =>
      _filtered.length - _initialLimit;

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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _displayList.length + (_showMoreVisible ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_showMoreVisible && i == _displayList.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showAll = true),
                            icon: const Icon(Icons.expand_more),
                            label: Text('Lihat semua ($_hiddenCount lainnya)'),
                          ),
                        ),
                      );
                    }
                    final item = _displayList[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 72,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.code,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        title: Text(item.description,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: item.chapter != null
                            ? Text('Chapter ${item.chapter}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.outline))
                            : null,
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(code: item),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool get _showMoreVisible =>
      !_isSearching && !_showAll && _hiddenCount > 0;
}
