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
  final FocusNode _focusNode = FocusNode();
  List<IcdCode> _allCodes = [];
  bool _loading = true;
  bool _showAll = false;
  String _query = '';
  Timer? _debounce;
  String? _selectedChapter;
  String? _selectedBodyPart;
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

  List<IcdCode> get _suggestions {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _allCodes.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
    }).take(5).toList();
  }

  bool get _showSuggestions => _focusNode.hasFocus && _query.trim().isNotEmpty;

  void _selectSuggestion(IcdCode code) {
    _controller.text = code.code;
    _controller.selection = TextSelection.collapsed(offset: code.code.length);
    _focusNode.unfocus();
    setState(() => _query = code.code);
  }

  static const _bodyParts = <String, List<String>>{
    'Tengkorak & Saraf': ['head', 'brain', 'cranial', 'cerebral', 'neurolog', 'nerve', 'spinal', 'mening'],
    'Mata': ['eye', 'ocular', 'ophthalmi', 'retina', 'cornea', 'conjunctiv', 'lens', 'vision', 'blind'],
    'Telinga': ['ear', 'otitis', 'audiolog', 'hearing', 'tympanic', 'cochlear'],
    'Mulut & Tenggorokan': ['mouth', 'oral', 'throat', 'pharynx', 'larynx', 'tonsil', 'gingiva', 'tongue', 'salivary', 'esophag'],
    'Jantung & Pembuluh': ['heart', 'cardiac', 'cardiovascular', 'myocardi', 'coronary', 'valv', 'arrhythmi', 'pericard', 'endocard', 'atheroscler', 'hypertension', 'blood pressure'],
    'Paru & Pernapasan': ['lung', 'pulmonary', 'respirat', 'bronch', 'pneumon', 'asthma', 'pleura', 'trachea', 'emphysema', 'tubercul'],
    'Perut & Pencernaan': ['stomach', 'gastr', 'intestin', 'colon', 'rectal', 'hepat', 'liver', 'pancrea', 'bile', 'gallbladder', 'hernia', 'appendi', 'periton'],
    'Kulit': ['skin', 'dermat', 'rash', 'urticaria', 'eczema', 'psoria', 'melanoma', 'ulcer', 'subcutane'],
    'Tulang & Otot': ['bone', 'skeletal', 'muscle', 'fracture', 'arthr', 'joint', 'osteo', 'rheum', 'spine', 'vertebr', 'ligament', 'tendon'],
    'Ginjal & Kelamin': ['kidney', 'ren', 'urinar', 'bladder', 'prostat', 'uterus', 'ovarian', 'cervi', 'vagin', 'penile', 'testi', 'genit', 'neonat'],
    'Darah': ['blood', 'anemia', 'hematolog', 'leukemia', 'lymph', 'coagul', 'thrombocyt', 'hemoglobin', 'hemorrhag'],
    'Hormon & Metabolik': ['thyroid', 'diabetes', 'hormon', 'metabol', 'pituit', 'adrenal', 'obes', 'nutrition', 'vitamin'],
    'Mental & Perilaku': ['mental', 'psych', 'anxiety', 'depress', 'schizo', 'personality', 'disorder', 'dementia', 'alcohol', 'substance', 'sleep'],
  };

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
    if (_selectedBodyPart != null) {
      final keywords = _bodyParts[_selectedBodyPart]!;
      result = result.where((c) {
        final desc = c.description.toLowerCase();
        return keywords.any((k) => desc.contains(k));
      }).toList();
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
    _focusNode.dispose();
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
                focusNode: _focusNode,
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
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_suggestions.length, (i) {
                final s = _suggestions[i];
                final isLast = i == _suggestions.length - 1;
                return InkWell(
                  onTap: () => _selectSuggestion(s),
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 12, 14, isLast ? 12 : 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(Icons.search, size: 16, color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        if (!_loading && (_chapters.length > 1 || _bodyParts.isNotEmpty))
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  avatar: Icon(Icons.favorite_border, size: 14, color: _selectedBodyPart != null ? Colors.white : widget.color.withValues(alpha: 0.7)),
                  label: Text(
                    _selectedBodyPart ?? 'Tubuh',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedBodyPart != null ? Colors.white : widget.color.withValues(alpha: 0.7),
                    ),
                  ),
                  selected: _selectedBodyPart != null,
                  onSelected: (_) {
                    if (_selectedBodyPart != null) {
                      setState(() => _selectedBodyPart = null);
                    } else {
                      _showBodyPartPicker();
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  selectedColor: widget.color,
                  showCheckmark: false,
                ),
                const SizedBox(width: 6),
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
                    return _IcdCard(item: item, color: widget.color, theme: theme, query: _query);
                  },
                ),
        ),
      ],
    );
  }

  bool get _showMoreVisible => !_isSearching && !_showAll && _hiddenCount > 0;

  void _showBodyPartPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Bagian Tubuh', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Pilih bagian tubuh untuk mempersempit hasil', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bodyParts.keys.map((part) {
                final selected = _selectedBodyPart == part;
                return ChoiceChip(
                  label: Text(part, style: TextStyle(fontSize: 13, color: selected ? Colors.white : null)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedBodyPart = selected ? null : part);
                    Navigator.pop(ctx);
                  },
                  selectedColor: widget.color,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

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
  final String query;

  const _IcdCard({
    required this.item,
    required this.color,
    required this.theme,
    this.query = '',
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

  List<InlineSpan> _highlight(String text, TextStyle baseStyle) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [TextSpan(text: text, style: baseStyle)];

    final lower = text.toLowerCase();
    final spans = <InlineSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) break;
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: baseStyle.copyWith(
          backgroundColor: color.withValues(alpha: 0.25),
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ));
      start = idx + q.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return spans;
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
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: _highlight(item.code, TextStyle(
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontSize: 12,
                            letterSpacing: 1,
                            height: 1.3,
                          )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: _highlight(item.description, TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: theme.colorScheme.onSurface,
                            )),
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
