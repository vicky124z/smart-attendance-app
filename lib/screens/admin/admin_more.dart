import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Administration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MenuTile(icon: Icons.people, title: 'Role Management', onTap: () {}),
          _MenuTile(icon: Icons.security, title: 'Permission Management', onTap: () {}),
          _MenuTile(icon: Icons.history, title: 'Audit Logs', onTap: () {}),
          _MenuTile(icon: Icons.backup, title: 'Backup Database', onTap: () {}),
          _MenuTile(icon: Icons.restore, title: 'Restore Database', onTap: () {}),
          const SizedBox(height: 20),
          const Text('System', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MenuTile(icon: Icons.settings, title: 'System Settings', onTap: () {}),
          _MenuTile(icon: Icons.campaign, title: 'Manage Announcements', onTap: () {}),
          _MenuTile(icon: Icons.info_outline, title: 'About App', onTap: () {}),
          const SizedBox(height: 20),
          _MenuTile(
            icon: Icons.logout,
            title: 'Logout',
            color: AppColors.danger,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({required this.icon, required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        onTap: onTap,
      ),
    );
  }
}
