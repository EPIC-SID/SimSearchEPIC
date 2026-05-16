import 'package:flutter/material.dart';
import 'theme.dart';
import 'sidebar.dart';
import 'widgets.dart';

final _mockResults = [
  SearchResult(
    name: 'Misty Alpine Lake',
    path: '',
    score: 0.98,
    imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=800',
    tags: ['Nature', 'Mountains', 'Lake'],
  ),
  SearchResult(
    name: 'Rolling Green Hills',
    path: '',
    score: 0.95,
    imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=800',
    tags: ['Landscape', 'Summer', 'Fields'],
  ),
  SearchResult(
    name: 'Desert Sunset Dunes',
    path: '',
    score: 0.92,
    imageUrl: 'https://images.unsplash.com/photo-1473580044384-7ba9967e16a0?auto=format&fit=crop&q=80&w=800',
    tags: ['Desert', 'Sunset', 'Nature'],
  ),
  SearchResult(
    name: 'Forest Stream Flow',
    path: '',
    score: 0.89,
    imageUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&q=80&w=800',
    tags: ['Forest', 'Water', 'Peaceful'],
  ),
  SearchResult(
    name: 'Snowy Peak Vista',
    path: '',
    score: 0.86,
    imageUrl: 'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?auto=format&fit=crop&q=80&w=800',
    tags: ['Winter', 'Snow', 'Mountains'],
  ),
  SearchResult(
    name: 'Coastal Cliff Edge',
    path: '',
    score: 0.83,
    imageUrl: 'https://images.unsplash.com/photo-1505228395891-9a51e7e86bf6?auto=format&fit=crop&q=80&w=800',
    tags: ['Ocean', 'Cliff', 'Travel'],
  ),
];

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
                      // Back button
                      Padding(
                        padding: const EdgeInsets.only(right: 16, top: 2),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.bg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
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
            if (widget.item.imageUrl != null)
              Image.network(widget.item.imageUrl!, fit: BoxFit.cover)
            else
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
