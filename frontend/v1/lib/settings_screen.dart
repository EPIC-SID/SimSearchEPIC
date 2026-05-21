import 'package:flutter/material.dart';
import 'theme.dart';
import 'sidebar.dart';
import 'services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();

  // Confidence threshold
  double _confidenceThreshold = 0.24;
  bool _loadingConfig = true;

  // Backend connection
  final TextEditingController _hostCtrl = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portCtrl = TextEditingController(text: '8000');

  // Folder paths
  List<String> _folderPaths = [];
  final TextEditingController _newFolderCtrl = TextEditingController();

  // Backend health
  String _backendStatus = 'Checking...';
  int _indexedCount = 0;
  bool _backendOnline = false;

  // Save state
  bool _saving = false;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _newFolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loadingConfig = true);

    // Check backend health
    try {
      final health = await _api.health();
      if (!mounted) return;
      setState(() {
        _backendOnline = health.isReady;
        _backendStatus = health.isReady ? 'Online' : 'Index empty';
        _indexedCount = health.indexedCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backendOnline = false;
        _backendStatus = 'Offline';
        _indexedCount = 0;
      });
    }

    // Load config from backend
    try {
      final config = await _api.getConfig();
      if (!mounted) return;
      setState(() {
        _confidenceThreshold = config['confidence_threshold'] ?? 0.24;
        _folderPaths = List<String>.from(config['folder_paths'] ?? []);
      });
    } catch (_) {
      // Use defaults if config endpoint unavailable
    }

    if (mounted) setState(() => _loadingConfig = false);
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
      _saveMessage = null;
    });

    try {
      await _api.updateConfig(
        confidenceThreshold: _confidenceThreshold,
        folderPaths: _folderPaths,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveMessage = 'Settings saved successfully';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _saveMessage = null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveMessage = 'Failed to save: $e';
      });
    }
  }

  void _addFolder() {
    final path = _newFolderCtrl.text.trim();
    if (path.isEmpty || _folderPaths.contains(path)) return;
    setState(() {
      _folderPaths.add(path);
      _newFolderCtrl.clear();
    });
  }

  void _removeFolder(int index) {
    setState(() => _folderPaths.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSidebar(
            activePage: 'settings',
            onNavigate: (page) {
              if (page == 'search') Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  color: AppTheme.white,
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.activeBlueLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.settings_outlined, size: 22, color: AppTheme.activeBlue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settings', style: AppTheme.outfit(26, FontWeight.w700, AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              'Configure search engine, indexed folders, and backend connection',
                              style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (_saveMessage != null)
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _saveMessage!.startsWith('Failed')
                                  ? const Color(0xFFFDE7E7)
                                  : const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _saveMessage!.startsWith('Failed') ? Icons.error_outline : Icons.check_circle_outline,
                                  size: 16,
                                  color: _saveMessage!.startsWith('Failed')
                                      ? const Color(0xFFD93025)
                                      : const Color(0xFF188038),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _saveMessage!,
                                  style: AppTheme.inter(
                                    12,
                                    FontWeight.w500,
                                    _saveMessage!.startsWith('Failed')
                                        ? const Color(0xFFD93025)
                                        : const Color(0xFF188038),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _saveSettings,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                              )
                            : const Icon(Icons.save_outlined, size: 16),
                        label: Text(_saving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.activeBlue,
                          foregroundColor: AppTheme.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: AppTheme.inter(13, FontWeight.w600, AppTheme.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                // Body
                Expanded(
                  child: _loadingConfig
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.activeBlue))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSearchSection(),
                                  const SizedBox(height: 24),
                                  _buildFoldersSection(),
                                  const SizedBox(height: 24),
                                  _buildBackendSection(),
                                ],
                              ),
                            ),
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

  // ── Search Engine Settings ──────────────────────────────────────────────────
  Widget _buildSearchSection() {
    return _SettingsCard(
      icon: Icons.tune_outlined,
      title: 'Search Engine',
      subtitle: 'Configure how search results are filtered and ranked',
      children: [
        // Confidence Threshold
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confidence Threshold', style: AppTheme.inter(14, FontWeight.w600, AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    'Only show results with similarity score above this value. '
                    'Lower values return more results but with less accuracy.',
                    style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.activeBlueLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                          style: AppTheme.inter(14, FontWeight.w700, AppTheme.activeBlue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppTheme.activeBlue,
                            inactiveTrackColor: AppTheme.border,
                            thumbColor: AppTheme.activeBlue,
                            overlayColor: AppTheme.activeBlue.withValues(alpha: 0.12),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _confidenceThreshold,
                            min: 0.05,
                            max: 0.95,
                            divisions: 90,
                            onChanged: (v) => setState(() => _confidenceThreshold = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('More results', style: AppTheme.inter(11, FontWeight.w400, AppTheme.textHint)),
                      Text('Higher accuracy', style: AppTheme.inter(11, FontWeight.w400, AppTheme.textHint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Indexed Folders ─────────────────────────────────────────────────────────
  Widget _buildFoldersSection() {
    return _SettingsCard(
      icon: Icons.folder_outlined,
      title: 'Indexed Folders',
      subtitle: 'Directories that are scanned and indexed for image search',
      children: [
        // Add folder input
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _newFolderCtrl,
                  onSubmitted: (_) => _addFolder(),
                  style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter folder path (e.g. C:\\Photos)',
                    hintStyle: AppTheme.inter(13, FontWeight.w400, AppTheme.textHint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.create_new_folder_outlined, size: 18, color: AppTheme.textHint),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _addFolder,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.btnBlack,
                foregroundColor: AppTheme.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: AppTheme.inter(13, FontWeight.w600, AppTheme.white),
              ),
            ),
          ],
        ),
        if (_folderPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(_folderPaths.length, (i) {
                final isLast = i == _folderPaths.length - 1;
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.folder, size: 18, color: const Color(0xFFFBBC04)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _folderPaths[i],
                          style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => _removeFolder(i),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 16, color: AppTheme.textHint),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
        if (_folderPaths.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.textHint),
                const SizedBox(width: 8),
                Text('No folders configured. Add a folder to start indexing.',
                    style: AppTheme.inter(13, FontWeight.w400, AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Backend Connection ──────────────────────────────────────────────────────
  Widget _buildBackendSection() {
    return _SettingsCard(
      icon: Icons.dns_outlined,
      title: 'Backend Connection',
      subtitle: 'Server status and system information',
      children: [
        // Status row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _backendOnline ? const Color(0xFFF1F9F1) : const Color(0xFFFEF7F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _backendOnline ? const Color(0xFFC8E6C9) : const Color(0xFFFDD8B3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _backendOnline ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  boxShadow: [
                    BoxShadow(
                      color: (_backendOnline ? const Color(0xFF4CAF50) : const Color(0xFFFF9800))
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_backendStatus',
                      style: AppTheme.inter(13, FontWeight.w600, AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _backendOnline
                          ? '$_indexedCount images indexed and ready'
                          : 'Start the backend with: python api.py',
                      style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadSettings,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: AppTheme.inter(12, FontWeight.w500, AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Connection details
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Host',
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    controller: _hostCtrl,
                    style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: _LabeledField(
                label: 'Port',
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    controller: _portCtrl,
                    style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Info grid
        Row(
          children: [
            _InfoChip(label: 'Model', value: 'CLIP ViT-B/32'),
            const SizedBox(width: 10),
            _InfoChip(label: 'Index', value: 'FAISS (IP)'),
            const SizedBox(width: 10),
            _InfoChip(label: 'Database', value: 'SQLite'),
          ],
        ),
      ],
    );
  }
}

// ── Reusable settings card ──────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.activeBlue),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.outfit(16, FontWeight.w600, AppTheme.textPrimary)),
                    const SizedBox(height: 1),
                    Text(subtitle, style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Labeled field ─────────────────────────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.inter(12, FontWeight.w500, AppTheme.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.inter(11, FontWeight.w400, AppTheme.textHint)),
            const SizedBox(height: 3),
            Text(value, style: AppTheme.inter(13, FontWeight.w600, AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
