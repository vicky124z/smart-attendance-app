import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'students_list.dart';
import 'teachers_list.dart';
import 'courses_list.dart';
import 'departments_list.dart';
import 'attendance_analytics.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Manage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.people,
            title: 'Students',
            onTap: () => _open(context, const StudentsListScreen()),
          ),
          _MenuTile(
            icon: Icons.school,
            title: 'Teachers',
            onTap: () => _open(context, const TeachersListScreen()),
          ),
          _MenuTile(
            icon: Icons.business,
            title: 'Departments',
            onTap: () => _open(context, const DepartmentsListScreen()),
          ),
          _MenuTile(
            icon: Icons.menu_book,
            title: 'Courses',
            onTap: () => _open(context, const CoursesListScreen()),
          ),
          _MenuTile(
            icon: Icons.bar_chart,
            title: 'Attendance Analytics',
            onTap: () => _open(context, const AttendanceAnalyticsScreen()),
          ),
          const SizedBox(height: 20),
          const Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.logout,
            title: 'Logout',
            color: AppColors.danger,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              }
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
