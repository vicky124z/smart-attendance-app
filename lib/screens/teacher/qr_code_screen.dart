import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/app_colors.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class QRCodeScreen extends StatefulWidget {
  final AttendanceSessionModel session;

  const QRCodeScreen({super.key, required this.session});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  late AttendanceSessionModel _session;
  Timer? _pollTimer;
  Timer? _tickTimer;
  Duration _remaining = Duration.zero;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _remaining = _session.remaining;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshStatus());
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _session.remaining);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    try {
      final updated = await AttendanceService.instance.sessionStatus(_session.id);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _remaining = updated.remaining;
      });
      if (!updated.isActive) {
        _pollTimer?.cancel();
        _tickTimer?.cancel();
      }
    } catch (_) {
      // Silently ignore transient polling errors.
    }
  }

  Future<void> _endSession() async {
    setState(() => _ending = true);
    try {
      await AttendanceService.instance.closeSession(_session.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.isNegative || !_session.isActive;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${_session.courseName} (${_session.courseCode})',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Session ID: ${_session.id.length >= 8 ? _session.id.substring(0, 8).toUpperCase() : _session.id.toUpperCase()}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16),
                ],
              ),
              child: QrImageView(
                data: _session.qrPayload,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan this QR code to mark\nattendance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: expired ? const Color(0xFFE5E7EB) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: expired ? AppColors.textSecondary : AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    expired ? 'Session ended' : 'Expires in  ${_formatDuration(_remaining)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: expired ? AppColors.textSecondary : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'Students Marked',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${_session.markedCount} / ${_session.totalEnrolled}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: (_ending || expired) ? (expired ? () => Navigator.pop(context) : null) : _endSession,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  foregroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _ending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.danger),
                      )
                    : Text(
                        expired ? 'Close' : 'End Session',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
