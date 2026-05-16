import 'package:flutter/material.dart';
import 'theme.dart';
import 'sidebar.dart';
import 'widgets.dart';
import 'results_screen.dart';

// Mock results for UI demo
final _mockResults = List.generate(
  6,
  (i) => SearchResult(path: 'C:/nonexistent/img_$i.jpg', score: 0.99 - i * 0.03),
);

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _ctrl = TextEditingController();
  SearchResult? _selected = _mockResults[0];
  final List<SearchResult> _results = _mockResults;

  void _doSearch(String q) {
    if (q.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultsScreen(query: q)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Top bar
          _TopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSidebar(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search hero
                      Container(
                        color: AppTheme.white,
                        padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                        child: Column(
                          children: [
                            Text('Find Similar Assets',
                                style: AppTheme.outfit(42, FontWeight.w700, AppTheme.textPrimary,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 28),
                            // Search bar
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(color: AppTheme.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 18),
                                    Icon(Icons.search, color: AppTheme.textHint, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _ctrl,
                                        onSubmitted: _doSearch,
                                        style: AppTheme.inter(15, FontWeight.w400, AppTheme.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: 'Upload image or paste URL to discover visually similar assets...',
                                          hintStyle: AppTheme.inter(14, FontWeight.w400, AppTheme.textHint),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: ElevatedButton(
                                        onPressed: () => _doSearch(_ctrl.text),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.activeBlue,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(12),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.upload_file, size: 18, color: AppTheme.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Suggestion chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: ['Architecture', 'Portraits', 'Landscapes'].map((tag) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => _doSearch(tag),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.border),
                                      ),
                                      child: Text(tag, style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.border),
                      // Results + Details
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _ResultsGrid(results: _results, onSelect: (r) => setState(() => _selected = r))),
                            AssetDetailsPanel(item: _selected, onClose: () => setState(() => _selected = null)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('SimSearch', style: AppTheme.outfit(16, FontWeight.w700, AppTheme.textPrimary)),
          IconButton(
            icon: Icon(Icons.account_circle_outlined, color: AppTheme.textSecondary, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// Bento grid layout
class _ResultsGrid extends StatelessWidget {
  final List<SearchResult> results;
  final ValueChanged<SearchResult> onSelect;
  const _ResultsGrid({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Results', style: AppTheme.outfit(18, FontWeight.w600, AppTheme.textPrimary)),
                Text('Showing 24 matches', style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text('No results yet', style: AppTheme.inter(14, FontWeight.w400, AppTheme.textHint)))
                : _BentoLayout(results: results, onSelect: onSelect),
          ),
        ],
      ),
    );
  }
}

class _BentoLayout extends StatelessWidget {
  final List<SearchResult> results;
  final ValueChanged<SearchResult> onSelect;
  const _BentoLayout({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 12.0;
      const cols = 4;
      final w = constraints.maxWidth;
      final cellW = (w - 32 * 2 - gap * (cols - 1)) / cols;
      const cellH = 160.0;

      // Bento positions: item 0 is 2×2
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          height: cellH * 3 + gap * 2 + 8,
          child: Stack(children: [
            if (results.isNotEmpty)
              Positioned(
                left: 0, top: 0,
                width: cellW * 2 + gap, height: cellH * 2 + gap,
                child: ImageCard(item: results[0], featured: true, onTap: () => onSelect(results[0])),
              ),
            // Col 2, row 0
            if (results.length > 1)
              Positioned(left: (cellW + gap) * 2, top: 0, width: cellW, height: cellH,
                  child: ImageCard(item: results[1], onTap: () => onSelect(results[1]))),
            // Col 3, row 0
            if (results.length > 2)
              Positioned(left: (cellW + gap) * 3, top: 0, width: cellW, height: cellH,
                  child: ImageCard(item: results[2], onTap: () => onSelect(results[2]))),
            // Col 3, row 1 (tall — 2 rows)
            if (results.length > 3)
              Positioned(left: (cellW + gap) * 2, top: cellH + gap, width: cellW * 2 + gap, height: cellH * 2 + gap,
                  child: ImageCard(item: results[3], onTap: () => onSelect(results[3]))),
            // Col 0, row 2
            if (results.length > 4)
              Positioned(left: 0, top: (cellH + gap) * 2, width: cellW, height: cellH,
                  child: ImageCard(item: results[4], onTap: () => onSelect(results[4]))),
            // Col 1, row 2
            if (results.length > 5)
              Positioned(left: cellW + gap, top: (cellH + gap) * 2, width: cellW, height: cellH,
                  child: ImageCard(item: results[5], onTap: () => onSelect(results[5]))),
          ]),
        ),
      );
    });
  }
}
