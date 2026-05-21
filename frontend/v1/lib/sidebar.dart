import 'package:flutter/material.dart';
import 'theme.dart';

class AppSidebar extends StatelessWidget {
  final bool showUserAccount;
  final String activePage;
  final void Function(String)? onNavigate;

  const AppSidebar({
    super.key,
    this.showUserAccount = false,
    this.activePage = 'search',
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.image_search_rounded, size: 28, color: AppTheme.activeBlue),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SimSearch', style: AppTheme.outfit(16, FontWeight.w700, AppTheme.textPrimary)),
                    Text('Image Engine', style: AppTheme.inter(11, FontWeight.w400, AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Search nav item
          _navItem(Icons.search, 'Search', activePage == 'search', () {
            if (activePage != 'search') onNavigate?.call('search');
          }),
          const SizedBox(height: 4),
          // Settings nav item
          _navItem(Icons.settings_outlined, 'Settings', activePage == 'settings', () {
            if (activePage != 'settings') onNavigate?.call('settings');
          }),
          const Spacer(),
          if (showUserAccount) ...[
            const Divider(color: AppTheme.border, thickness: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.bg,
                    child: Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Text('User Account', style: AppTheme.inter(13, FontWeight.w400, AppTheme.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? AppTheme.activeBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: active ? AppTheme.white : AppTheme.textSecondary),
                const SizedBox(width: 10),
                Text(label,
                    style: AppTheme.inter(14, active ? FontWeight.w600 : FontWeight.w400,
                        active ? AppTheme.white : AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
