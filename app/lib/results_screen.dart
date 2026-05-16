import 'package:flutter/material.dart';
import 'theme.dart';
import 'sidebar.dart';
import 'widgets.dart';

final _mockResults = List.generate(
  6,
  (i) => SearchResult(path: 'C:/nonexistent/img_$i.jpg', score: 0.95 - i * 0.03),
);

class ResultsScreen extends StatelessWidget {
  final String query;
  const ResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSidebar(showUserAccount: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page header
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Image Search Results',
                                style: AppTheme.outfit(28, FontWeight.w700, AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Showing 24 results for "$query"',
                                style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      // Filter chips
                      Row(
                        children: ['All Formats', 'Photography', 'Vectors'].map((f) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(f, style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 20),
                // Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    child: Column(
                      children: [
                        // 3-column equal grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _mockResults.length,
                          itemBuilder: (ctx, i) => _GridImageCard(item: _mockResults[i]),
                        ),
                        const SizedBox(height: 36),
                        // Load more button
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: const BorderSide(color: AppTheme.border),
                            foregroundColor: AppTheme.textPrimary,
                          ),
                          child: Text('Load More Results',
                              style: AppTheme.inter(14, FontWeight.w400, AppTheme.textPrimary)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
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

class _GridImageCard extends StatefulWidget {
  final SearchResult item;
  const _GridImageCard({required this.item});

  @override
  State<_GridImageCard> createState() => _GridImageCardState();
}

class _GridImageCardState extends State<_GridImageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppTheme.imagePlaceholder,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hovered ? AppTheme.activeBlue : AppTheme.border),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppTheme.imagePlaceholder),
            if (_hovered)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.activeBlue,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 0,
                    ),
                    child: Text('View Details', style: AppTheme.inter(13, FontWeight.w600, AppTheme.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
