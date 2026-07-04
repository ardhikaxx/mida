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
  List<IcdCode> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final codes = await _service.load(widget.type);
    setState(() {
      _allCodes = codes;
      _filtered = codes;
      _loading = false;
    });
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allCodes
          : _allCodes.where((c) {
              return c.code.toLowerCase().contains(q) ||
                  c.description.toLowerCase().contains(q) ||
                  (c.chapter?.toLowerCase().contains(q) ?? false) ||
                  (c.chapterTitle?.toLowerCase().contains(q) ?? false);
            }).toList();
    });
  }

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
                        _filter('');
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
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final item = _filtered[i];
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
}
