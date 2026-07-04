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
  List<IcdCode> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await _service.search(widget.type, query);
    setState(() {
      _results = results;
      _loading = false;
    });
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
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Cari kode atau nama ${widget.type.label}...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
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
              setState(() {});
              if (v.length >= 2) _search(v);
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('Ketik minimal 2 karakter untuk mencari',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.outline)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final item = _results[i];
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
