import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/attendance_service.dart';
import '../../providers/auth_provider.dart';
import 'create_session.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _TeacherHome(),
    CreateSessionScreen(),
    _TeacherReports(),
    _TeacherMore(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class _TeacherHome extends StatefulWidget {
  const _TeacherHome();

  @override
  State<_TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<_TeacherHome> {
  final _attendanceService = AttendanceService.instance;
  bool _loading = true;
  String? _error;
  int _todaysClasses = 0;
  int _sessionsToday = 0;
  int _presentToday = 0;
  int _absentToday = 0;
  List<Map<String, dynamic>> _schedule = [];

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
      final data = await _attendanceService.teacherDashboard();
      setState(() {
        _todaysClasses = data['todays_classes_count'] ?? 0;
        _sessionsToday = data['attendance_sessions_today'] ?? 0;
        _presentToday = data['present_students_today'] ?? 0;
        _absentToday = data['absent_students_today'] ?? 0;
        _schedule = List<Map<String, dynamic>>.from(data['todays_schedule'] ?? []);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                value: '$_todaysClasses',
                                label: "Today's Classes",
                                color: AppColors.primary,
                                icon: Icons.class_,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatBox(
                                value: '$_sessionsToday',
                                label: 'Attendance Sessions',
                                color: AppColors.secondary,
                                icon: Icons.how_to_reg,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                value: '$_presentToday',
                                label: 'Present Students',
                                color: AppColors.secondary,
                                icon: Icons.people,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatBox(
                                value: '$_absentToday',
                                label: 'Absent Students',
                                color: AppColors.danger,
                                icon: Icons.person_off,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Today's Schedule",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_schedule.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No classes scheduled for today.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ..._schedule.map((s) => _ScheduleTile(
                                course: s['course'] ?? '',
                                time: s['time'] ?? '',
                                room: s['room'] ?? '',
                                color: AppColors.primary,
                              )),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

/// Live teacher report from `/attendance/dashboard/teacher/`.
class _TeacherReports extends StatefulWidget {
  const _TeacherReports();

  @override
  State<_TeacherReports> createState() => _TeacherReportsState();
}

class _TeacherReportsState extends State<_TeacherReports> {
  final _service = AttendanceService.instance;
  bool _loading = true;
  String? _error;
  int _todaysClasses = 0;
  int _sessionsToday = 0;
  int _presentToday = 0;
  int _absentToday = 0;
  List<Map<String, dynamic>> _schedule = [];

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
      final data = await _service.teacherDashboard();
      setState(() {
        _todaysClasses = data['todays_classes_count'] ?? 0;
        _sessionsToday = data['attendance_sessions_today'] ?? 0;
        _presentToday = data['present_students_today'] ?? 0;
        _absentToday = data['absent_students_today'] ?? 0;
        _schedule = List<Map<String, dynamic>>.from(data['todays_schedule'] ?? []);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _presentRate {
    final total = _presentToday + _absentToday;
    if (total == 0) return 0;
    return (_presentToday / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text("Today's Attendance Rate", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text(
                              '${_presentRate.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            Text(
                              '$_presentToday present · $_absentToday absent',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReportRow(label: "Today's classes", value: '$_todaysClasses'),
                      _ReportRow(label: 'Sessions created today', value: '$_sessionsToday'),
                      _ReportRow(label: 'Students present', value: '$_presentToday', valueColor: AppColors.secondary),
                      _ReportRow(label: 'Students absent', value: '$_absentToday', valueColor: AppColors.danger),
                      const SizedBox(height: 20),
                      const Text("Today's Schedule", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      if (_schedule.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No classes scheduled for today.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ..._schedule.map((s) => _ScheduleTile(
                              course: s['course'] ?? '',
                              time: s['time'] ?? '',
                              room: s['room'] ?? '',
                              color: AppColors.primary,
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReportRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TeacherMore extends StatelessWidget {
  const _TeacherMore();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFD1FAE5),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        if (user.department != null)
                          Text(user.department!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatBox({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String course;
  final String time;
  final String room;
  final Color color;

  const _ScheduleTile({required this.course, required this.time, required this.room, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$time  ·  $room', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
