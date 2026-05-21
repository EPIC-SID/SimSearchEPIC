import 'package:flutter/material.dart';
import 'theme.dart';
import 'sidebar.dart';
import 'settings_screen.dart';
import 'widgets.dart';
import 'services/api_service.dart';

class ResultsScreen extends StatefulWidget {
  final String query;
  const ResultsScreen({super.key, required this.query});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _api = ApiService();
  late Future<SearchResponse> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _api.search(widget.query);
  }

  void _retry() {
    setState(() {
      _searchFuture = _api.search(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSidebar(
            showUserAccount: true,
            activePage: 'search',
            onNavigate: (page) {
              if (page == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            FutureBuilder<SearchResponse>(
                              future: _searchFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Text('Searching for "${widget.query}"...',
                                      style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary));
                                }
                                return Text(
                                  'Showing ${snapshot.data!.results.length} results for "${widget.query}"',
                                  style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<SearchResponse>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppTheme.activeBlue),
                              SizedBox(height: 16),
                              Text('Searching your image library...'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        final err = snapshot.error;
                        final message = err is ApiException
                            ? err.message
                            : 'Could not reach the backend. Start it with: python api.py';
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.textHint),
                                const SizedBox(height: 16),
                                Text('Search unavailable',
                                    style: AppTheme.outfit(18, FontWeight.w600, AppTheme.textPrimary)),
                                const SizedBox(height: 8),
                                Text(message,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.inter(14, FontWeight.w400, AppTheme.textSecondary)),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _retry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.activeBlue,
                                    foregroundColor: AppTheme.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final results = snapshot.data!.results;
                      if (results.isEmpty) {
                        return Center(
                          child: Text('No results found for "${widget.query}"',
                              style: AppTheme.inter(14, FontWeight.w400, AppTheme.textSecondary)),
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: results.length,
                          itemBuilder: (ctx, i) => _GridImageCard(item: results[i]),
                        ),
                      );
                    },
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

class _GridImageCard extends StatelessWidget {
  final SearchResult item;
  const _GridImageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ImageCard(item: item, onTap: () {});
  }
}
