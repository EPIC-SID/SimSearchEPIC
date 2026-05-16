import 'package:flutter/material.dart';
import 'dart:io';
import 'theme.dart';

// ── Search result data model ──────────────────────────────────────────────────
class SearchResult {
  final String path;
  final double score;
  final String? imageUrl;   // network image URL for mock/demo
  final String assetId;
  final String resolution;
  final String format;
  final List<String> tags;
  final String name;

  const SearchResult({
    required this.path,
    required this.score,
    this.imageUrl,
    this.assetId = 'ASSET-0000',
    this.resolution = '1920 × 1080',
    this.format = 'JPEG (sRGB)',
    this.tags = const [],
    this.name = 'Asset',
  });
}

// ── Image card with hover overlay ─────────────────────────────────────────────
class ImageCard extends StatefulWidget {
  final SearchResult item;
  final bool featured;
  final VoidCallback onTap;
  const ImageCard({super.key, required this.item, this.featured = false, required this.onTap});

  @override
  State<ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.imagePlaceholder,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: Colors.black.withValues(alpha: _hovered ? 0.05 : 0.0),
              ),
              Positioned(
                top: widget.featured ? 12 : null,
                right: widget.featured ? 12 : null,
                bottom: widget.featured ? null : 10,
                left: widget.featured ? null : 10,
                child: _scoreBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Prefer network URL (mock/demo mode)
    if (widget.item.imageUrl != null) {
      return Image.network(
        widget.item.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.imagePlaceholder,
            child: const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              ),
            ),
          );
        },
        errorBuilder: (ctx, err, stack) {
          debugPrint('Image load error: $err');
          return Container(
            color: AppTheme.imagePlaceholder,
            child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 24)),
          );
        },
      );
    }
    // Fallback to local file
    final f = File(widget.item.path);
    if (f.existsSync()) return Image.file(f, fit: BoxFit.cover);
    return Container(color: AppTheme.imagePlaceholder);
  }

  Widget _scoreBadge() {
    final pct = '${(widget.item.score * 100).round()}%';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.featured ? 10 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(widget.featured ? 20 : 6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pct,
              style: AppTheme.inter(12, FontWeight.w600,
                  widget.featured ? AppTheme.activeBlue : AppTheme.textPrimary)),
          if (widget.featured) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_outline_rounded, size: 13, color: AppTheme.activeBlue),
          ]
        ],
      ),
    );
  }
}

// ── Asset details right panel ─────────────────────────────────────────────────
class AssetDetailsPanel extends StatelessWidget {
  final SearchResult? item;
  final VoidCallback onClose;
  const AssetDetailsPanel({super.key, this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(left: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Asset Details', style: AppTheme.outfit(18, FontWeight.w600, AppTheme.textPrimary)),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.imagePlaceholder,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item == null
                          ? null
                          : item!.imageUrl != null
                              ? Image.network(
                                  item!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, _) => Container(
                                    color: AppTheme.imagePlaceholder,
                                    child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24)),
                                  ),
                                )
                              : File(item!.path).existsSync()
                                  ? Image.file(File(item!.path), fit: BoxFit.cover)
                                  : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item != null)
                    Text(item!.name,
                        style: AppTheme.outfit(14, FontWeight.w600, AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  _MetaRow(label: 'Similarity Score', badge: item != null ? '${(item!.score * 100).toStringAsFixed(1)}%' : '--'),
                  _MetaRow(label: 'Source ID', value: item?.assetId ?? '--'),
                  _MetaRow(label: 'Resolution', value: item?.resolution ?? '--'),
                  _MetaRow(label: 'Format', value: item?.format ?? '--'),
                  const SizedBox(height: 12),
                  Text('Identified Features', style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: (item?.tags.isNotEmpty == true ? item!.tags : ['—'])
                        .map((t) => _FeatureChip(label: t))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ActionBtn(label: 'Download Asset', icon: Icons.download_outlined, filled: true),
                const SizedBox(height: 8),
                _ActionBtn(label: 'Find More Like This', icon: Icons.manage_search_outlined, filled: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? badge;
  const _MetaRow({required this.label, this.value, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary)),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.badgeBlueBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(badge!, style: AppTheme.inter(13, FontWeight.w600, AppTheme.badgeBlueText)),
                ),
              if (value != null)
                Text(value!, style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.border),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: AppTheme.inter(12, FontWeight.w400, AppTheme.textSecondary)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  const _ActionBtn({required this.label, required this.icon, required this.filled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: filled ? AppTheme.btnBlack : AppTheme.white,
          foregroundColor: filled ? AppTheme.white : AppTheme.btnBlack,
          side: BorderSide(color: filled ? Colors.transparent : AppTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTheme.inter(13, FontWeight.w600, AppTheme.white),
        ),
      ),
    );
  }
}
