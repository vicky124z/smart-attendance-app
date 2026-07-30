import '../../widgets/export_attendance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

/// Student reports built from live `/attendance/my-stats/` and
/// `/attendance/records/` data (no hardcoded dates).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = AttendanceService.instance;
  bool _loading = true;
  String? _error;
  MyAttendanceStats? _stats;
  List<AttendanceRecordModel> _records = [];
  int _tab = 0; // 0 = summary, 1 = subject detail

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
      final history = await _service.myHistory();
      setState(() {
        _stats = stats;
        _records = history;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _periodLabel {
    if (_records.isEmpty) return 'No records yet';
    final dates = _records.map((r) => r.markedAt).toList()..sort();
    final fmt = DateFormat('d MMM yyyy');
    if (dates.length == 1) return fmt.format(dates.first);
    return '${fmt.format(dates.first)} – ${fmt.format(dates.last)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export report',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => showExportAttendanceSheet(context),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _loading
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tab = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _tab == 0 ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Summary',
                                        style: TextStyle(
                                          color: _tab == 0 ? Colors.white : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tab = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _tab == 1 ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'By Subject',
                                        style: TextStyle(
                                          color: _tab == 1 ? Colors.white : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_tab == 0) _buildSummary() else _buildBySubject(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummary() {
    final stats = _stats!;
    return Column(
      children: [
        _ReportTile(
          icon: Icons.insights_rounded,
          title: 'Overall Attendance',
          subtitle: _periodLabel,
          trailing: '${stats.overallPercentage.toStringAsFixed(1)}%',
          trailingColor: AppColors.secondary,
        ),
        _ReportTile(
          icon: Icons.check_circle_outline,
          title: 'Classes Present',
          subtitle: 'Marked present this term',
          trailing: '${stats.present}',
          trailingColor: AppColors.secondary,
        ),
        _ReportTile(
          icon: Icons.cancel_outlined,
          title: 'Classes Absent',
          subtitle: 'Marked absent this term',
          trailing: '${stats.absent}',
          trailingColor: AppColors.danger,
        ),
        _ReportTile(
          icon: Icons.school_outlined,
          title: 'Total Classes',
          subtitle: 'All sessions counted',
          trailing: '${stats.total}',
        ),
        _ReportTile(
          icon: Icons.history,
          title: 'Attendance Records',
          subtitle: 'Entries in history',
          trailing: '${_records.length}',
        ),
      ],
    );
  }

  Widget _buildBySubject() {
    final subjects = _stats!.subjectWise;
    if (subjects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('No subject-wise data yet.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: subjects
          .map(
            (s) => _ReportTile(
              icon: Icons.menu_book_outlined,
              title: s.courseName,
              subtitle: '${s.present} present / ${s.total} total',
              trailing: '${s.percentage.toStringAsFixed(1)}%',
              trailingColor: s.percentage >= 75 ? AppColors.secondary : AppColors.warning,
            ),
          )
          .toList(),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color? trailingColor;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: trailingColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
