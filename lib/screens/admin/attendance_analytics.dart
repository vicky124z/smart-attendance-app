import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';
import '../../services/attendance_service.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  State<AttendanceAnalyticsScreen> createState() => _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  double _overallPercentage = 0;
  List<FlSpot> _trendSpots = [];
  List<Map<String, dynamic>> _departmentWise = [];

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
      final data = await AttendanceService.instance.adminAnalytics();
      final trend = List<Map<String, dynamic>>.from(data['trend'] ?? []);
      setState(() {
        _overallPercentage = (data['overall_percentage'] as num?)?.toDouble() ?? 0.0;
        _trendSpots = [
          for (int i = 0; i < trend.length; i++)
            FlSpot(i.toDouble(), (trend[i]['percentage'] as num?)?.toDouble() ?? 0.0),
        ];
        _departmentWise = List<Map<String, dynamic>>.from(data['department_wise'] ?? []);
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
      appBar: AppBar(title: const Text('Attendance Analytics (Admin)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overall
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text('Overall Attendance', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text('${_overallPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                              const Text('Last 7 days trend', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 160,
                                child: _trendSpots.isEmpty
                                    ? const Center(
                                        child: Text('No attendance data yet.', style: TextStyle(color: AppColors.textSecondary)),
                                      )
                                    : LineChart(
                                        LineChartData(
                                          gridData: const FlGridData(show: false),
                                          titlesData: const FlTitlesData(show: false),
                                          borderData: FlBorderData(show: false),
                                          minY: 0,
                                          maxY: 100,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _trendSpots,
                                              isCurved: true,
                                              color: AppColors.primary,
                                              barWidth: 3,
                                              dotData: const FlDotData(show: false),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Department wise
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
                              const Text('Department Wise', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              if (_departmentWise.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('No department data yet.', style: TextStyle(color: AppColors.textSecondary)),
                                )
                              else
                                ..._departmentWise.map((d) => _DeptBar(
                                      name: d['department'] ?? '',
                                      percent: ((d['percentage'] as num?)?.toDouble() ?? 0.0) / 100,
                                    )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _DeptBar extends StatelessWidget {
  final String name;
  final double percent;

  const _DeptBar({required this.name, required this.percent});

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
              Text(name, style: const TextStyle(fontSize: 13)),
              Text('${(percent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                percent >= 0.75 ? AppColors.secondary : (percent >= 0.7 ? AppColors.accent : AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
