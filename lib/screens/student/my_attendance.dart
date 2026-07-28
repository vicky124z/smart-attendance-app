import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../utils/app_colors.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Attendance'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Percentage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _HistoryTab(),
          _PercentageTab(),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _service = AttendanceService.instance;
  bool _loading = true;
  String? _error;
  List<AttendanceRecordModel> _records = [];

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
      final records = await _service.myHistory();
      setState(() => _records = records);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
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
      );
    }
    if (_records.isEmpty) {
      return const Center(child: Text('No attendance history yet.', style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final a = _records[index];
          final isPresent = a.isPresent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(a.markedAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${a.courseName} (${a.courseCode})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(a.markedAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPresent ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPresent ? AppColors.secondary : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PercentageTab extends StatefulWidget {
  const _PercentageTab();

  @override
  State<_PercentageTab> createState() => _PercentageTabState();
}

class _PercentageTabState extends State<_PercentageTab> {
  final _service = AttendanceService.instance;
  bool _loading = true;
  String? _error;
  MyAttendanceStats? _stats;

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
      final stats = await _service.myStats();
      setState(() => _stats = stats);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
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
      );
    }
    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Overall',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 80,
                    lineWidth: 14,
                    percent: (stats.overallPercentage / 100).clamp(0.0, 1.0),
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${stats.overallPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Text('Overall', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    progressColor: AppColors.secondary,
                    backgroundColor: AppColors.border,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Legend(
                        color: AppColors.secondary,
                        label: 'Present',
                        value: '${stats.present}',
                      ),
                      _Legend(
                        color: AppColors.danger,
                        label: 'Absent',
                        value: '${stats.absent}',
                      ),
                      _Legend(
                        color: AppColors.textSecondary,
                        label: 'Total Classes',
                        value: '${stats.total}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Wise',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (stats.subjectWise.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No subject data yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ...stats.subjectWise.map((s) => _SubjectBar(
                          name: s.courseName,
                          percent: s.percentage / 100,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final String name;
  final double percent;

  const _SubjectBar({required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                percent >= 0.75 ? AppColors.secondary : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
