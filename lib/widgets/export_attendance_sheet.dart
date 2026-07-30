import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/attendance_service.dart';
import '../services/api_exception.dart';
import '../utils/app_colors.dart';

/// Bottom sheet / dialog to export attendance as CSV (copied to clipboard).
Future<void> showExportAttendanceSheet(BuildContext context, {
  String? courseId,
  String? departmentId,
  String? studentId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExportSheet(
      courseId: courseId,
      departmentId: departmentId,
      studentId: studentId,
    ),
  );
}

class _ExportSheet extends StatefulWidget {
  final String? courseId;
  final String? departmentId;
  final String? studentId;

  const _ExportSheet({this.courseId, this.departmentId, this.studentId});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _loading = false;
  String? _error;
  int _count = 0;
  String? _csv;

  Future<void> _export() async {
    setState(() {
      _loading = true;
      _error = null;
      _csv = null;
    });
    try {
      final rows = await AttendanceService.instance.exportReport(
        courseId: widget.courseId,
        departmentId: widget.departmentId,
        studentId: widget.studentId,
      );
      final csv = AttendanceService.rowsToCsv(rows);
      setState(() {
        _count = rows.length;
        _csv = csv;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _copy() async {
    if (_csv == null) return;
    await Clipboard.setData(ClipboardData(text: _csv!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copied to clipboard')),
    );
  }

  @override
  void initState() {
    super.initState();
    _export();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Export Attendance Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generates a CSV of attendance records scoped to your role.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _export, child: const Text('Retry')),
              ],
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_count record${_count == 1 ? '' : 's'} ready for export',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy),
              label: const Text('Copy CSV to Clipboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }
}
