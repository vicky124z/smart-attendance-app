import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/attendance_service.dart';
import 'attendance_success.dart';

/// NOTE: This screen keeps the original camera-simulation UI (no camera
/// package is wired up yet). Tapping the capture button opens a manual
/// "enter session code" dialog which is then submitted to the real
/// POST /attendance/mark/ endpoint. Swap in a real QR scanner package
/// (e.g. mobile_scanner) later and call `_submitCode()` with the scanned
/// value to go fully hands-free.
class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _submitting = false;

  Future<void> _promptForCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Session Code'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'e.g. C9B9F0429FCC68A2',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) {
      await _submitCode(code);
    }
  }

  Future<void> _submitCode(String code) async {
    setState(() => _submitting = true);
    try {
      final record = await AttendanceService.instance.markAttendance(code);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AttendanceSuccessScreen(record: record)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Simulated camera background
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 200,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Scan frame
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Stack(
                    children: [
                      Positioned(top: 0, left: 0, child: _Corner(true, true)),
                      Positioned(top: 0, right: 0, child: _Corner(true, false)),
                      Positioned(bottom: 0, left: 0, child: _Corner(false, true)),
                      Positioned(bottom: 0, right: 0, child: _Corner(false, false)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 40,
                  child: Text(
                    'Tap the capture button and enter\nthe session code to mark attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const _ActionButton(icon: Icons.flash_on_rounded, label: 'Flash'),
                GestureDetector(
                  onTap: _submitting ? null : _promptForCode,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                const _ActionButton(icon: Icons.photo_library_outlined, label: 'Gallery'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _Corner(this.isTop, this.isLeft);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
