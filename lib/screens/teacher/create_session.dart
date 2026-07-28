import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/course_model.dart';
import '../../services/academics_service.dart';
import '../../services/attendance_service.dart';
import 'qr_code_screen.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  bool gpsEnabled = true;
  bool faceEnabled = true;

  final _durationController = TextEditingController(text: '60');
  final _roomController = TextEditingController();

  bool _loadingCourses = true;
  String? _loadError;
  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  String _sessionType = 'Lecture';
  bool _submitting = false;

  static const _sessionTypes = ['Lecture', 'Lab', 'Tutorial', 'Seminar'];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loadingCourses = true;
      _loadError = null;
    });
    try {
      final courses = await AcademicsService.instance.getCourses();
      setState(() {
        _courses = courses;
        _selectedCourse = courses.isNotEmpty ? courses.first : null;
        if (_selectedCourse != null && _selectedCourse!.schedules.isNotEmpty) {
          _roomController.text = _selectedCourse!.schedules.first.room;
        }
      });
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _loadingCourses = false);
    }
  }

  Future<void> _createSession() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first.')),
      );
      return;
    }
    final duration = int.tryParse(_durationController.text.trim()) ?? 60;

    setState(() => _submitting = true);
    try {
      final session = await AttendanceService.instance.createSession(
        courseId: _selectedCourse!.id,
        room: _roomController.text.trim().isEmpty ? 'TBD' : _roomController.text.trim(),
        sessionType: _sessionType,
        durationMinutes: duration,
        gpsVerification: gpsEnabled,
        faceRecognition: faceEnabled,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QRCodeScreen(session: session)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingCourses
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadCourses, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Class', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _CourseDropdown(
                        courses: _courses,
                        value: _selectedCourse,
                        onChanged: (c) => setState(() {
                          _selectedCourse = c;
                          if (c != null && c.schedules.isNotEmpty) {
                            _roomController.text = c.schedules.first.room;
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                      const Text('Room', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Room 204',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Session Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _SessionTypeDropdown(
                        value: _sessionType,
                        options: _sessionTypes,
                        onChanged: (v) => setState(() => _sessionType = v),
                      ),
                      const SizedBox(height: 16),
                      const Text('Duration (minutes)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '60',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ToggleRow(
                        title: 'Enable GPS Verification',
                        value: gpsEnabled,
                        onChanged: (v) => setState(() => gpsEnabled = v),
                      ),
                      _ToggleRow(
                        title: 'Enable Face Recognition',
                        value: faceEnabled,
                        onChanged: (v) => setState(() => faceEnabled = v),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _createSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                )
                              : const Text('Create Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CourseDropdown extends StatelessWidget {
  final List<CourseModel> courses;
  final CourseModel? value;
  final ValueChanged<CourseModel?> onChanged;

  const _CourseDropdown({required this.courses, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CourseModel>(
          isExpanded: true,
          value: value,
          hint: const Text('No courses available', style: TextStyle(fontSize: 15)),
          items: courses
              .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, style: const TextStyle(fontSize: 15))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SessionTypeDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SessionTypeDropdown({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 15))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
