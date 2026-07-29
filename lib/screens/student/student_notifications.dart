import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class StudentNotifications extends StatefulWidget {
  const StudentNotifications({super.key});

  @override
  State<StudentNotifications> createState() => _StudentNotificationsState();
}

class _StudentNotificationsState extends State<StudentNotifications> {
  final _service = NotificationService.instance;
  bool _loading = true;
  String? _error;
  List<NotificationModel> _all = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getNotifications();
      setState(() => _all = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<NotificationModel> get _filtered {
    switch (_filter) {
      case 'Unread':
        return _all.where((n) => !n.isRead).toList();
      case 'Important':
        return _all.where((n) => n.isImportant).toList();
      default:
        return _all;
    }
  }

  Future<void> _onTapNotification(NotificationModel n) async {
    if (!n.isRead) {
      try {
        await _service.markRead(n.id);
        setState(() {
          final idx = _all.indexWhere((x) => x.id == n.id);
          if (idx != -1) {
            _all[idx] = NotificationModel(
              id: n.id,
              type: n.type,
              title: n.title,
              subtitle: n.subtitle,
              isRead: true,
              isImportant: n.isImportant,
              time: n.time,
            );
          }
        });
      } catch (_) {
        // Non-fatal; ignore.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        // Used both as a tab and as a pushed route — only show back when we can pop.
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _filter == 'All', onTap: () => setState(() => _filter = 'All')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Unread', selected: _filter == 'Unread', onTap: () => setState(() => _filter = 'Unread')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Important', selected: _filter == 'Important', onTap: () => setState(() => _filter = 'Important')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(child: Text('No notifications here.', style: TextStyle(color: AppColors.textSecondary)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final n = _filtered[index];
                                return GestureDetector(
                                  onTap: () => _onTapNotification(n),
                                  child: _NotificationTile(
                                    title: n.title,
                                    subtitle: n.subtitle,
                                    time: n.time,
                                    type: n.type,
                                    isRead: n.isRead,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String type;
  final bool isRead;

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.isRead,
  });

  IconData get icon {
    switch (type) {
      case 'attendance':
        return Icons.check_circle_rounded;
      case 'session':
        return Icons.play_circle_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'attendance':
        return AppColors.secondary;
      case 'session':
        return AppColors.primary;
      case 'warning':
        return AppColors.warning;
      case 'announcement':
        return AppColors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get bgColor {
    switch (type) {
      case 'attendance':
        return const Color(0xFFECFDF5);
      case 'session':
        return const Color(0xFFEEF2FF);
      case 'warning':
        return const Color(0xFFFFF7ED);
      case 'announcement':
        return const Color(0xFFF5F3FF);
      default:
        return AppColors.background;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
