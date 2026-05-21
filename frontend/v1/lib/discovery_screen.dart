import 'package:flutter/material.dart';
import 'theme.dart';
import 'sidebar.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'services/api_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ApiService _api = ApiService();
  bool _searching = false;
  String? _backendMessage;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    try {
      final health = await _api.health();
      if (!mounted) return;
      setState(() {
        _backendMessage = health.isReady
            ? '${health.indexedCount} images indexed'
            : 'Backend running but index empty — run python index.py';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backendMessage = 'Backend offline — start with: python api.py';
      });
    }
  }

  Future<void> _doSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty || _searching) return;

    setState(() => _searching = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultsScreen(query: query)),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          _TopBar(backendMessage: _backendMessage),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSidebar(
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
                      Container(
                        color: AppTheme.white,
                        padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                        child: Column(
                          children: [
                            Text('Find Similar Assets',
                                style: AppTheme.outfit(42, FontWeight.w700, AppTheme.textPrimary,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 28),
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
                                        enabled: !_searching,
                                        onSubmitted: _doSearch,
                                        style: AppTheme.inter(15, FontWeight.w400, AppTheme.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: 'Describe what you are looking for (e.g. kitchen interior, mountain sunset)...',
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
                                        onPressed: _searching ? null : () => _doSearch(_ctrl.text),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.activeBlue,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(12),
                                          elevation: 0,
                                        ),
                                        child: _searching
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppTheme.white,
                                                ),
                                              )
                                            : const Icon(Icons.search, size: 18, color: AppTheme.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: ['Architecture', 'Portraits', 'Landscapes'].map((tag) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: _searching ? null : () => _doSearch(tag),
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
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(child: _EmptyHome()),
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
  final String? backendMessage;
  const _TopBar({this.backendMessage});

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
          if (backendMessage != null)
            Text(backendMessage!, style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary)),
          IconButton(
            icon: Icon(Icons.account_circle_outlined, color: AppTheme.textSecondary, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search_outlined, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text('Search to discover similar images',
                style: AppTheme.outfit(18, FontWeight.w600, AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Results from your indexed library will appear here',
                style: AppTheme.inter(14, FontWeight.w400, AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
