import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../services/academics_service.dart';
import '../../services/accounts_service.dart';
import '../../services/api_exception.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  bool _loading = true;
  String? _error;
  List<CourseModel> _courses = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AcademicsService.instance.getCourses(search: search);
      if (!mounted) return;
      setState(() {
        _courses = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(search: q));
  }

  Future<void> _openForm({CourseModel? course}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CourseFormDialog(course: course),
    );
    if (result == true) _load();
  }

  Future<void> _delete(CourseModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('Remove ${c.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AcademicsService.instance.deleteCourse(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Courses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.danger)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _courses.isEmpty
                        ? const Center(
                            child: Text('No courses found.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              final c = _courses[index];
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
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.menu_book, color: AppColors.purple),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.displayName,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          Text(
                                            [
                                              c.departmentName,
                                              if (c.teacherName != null) c.teacherName!,
                                              '${c.enrolledCount} enrolled',
                                            ].where((e) => e.isNotEmpty).join(' · '),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _openForm(course: c);
                                        if (v == 'delete') _delete(c);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _CourseFormDialog extends StatefulWidget {
  final CourseModel? course;
  const _CourseFormDialog({this.course});

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _semester;
  String? _departmentId;
  String? _teacherId;
  List<DepartmentModel> _departments = [];
  List<UserModel> _teachers = [];
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.course != null;

  String? get _safeDepartmentId {
    if (_departmentId == null) return null;
    if (_departments.isEmpty) return null;
    return _departments.any((d) => d.id == _departmentId) ? _departmentId : null;
  }

  String? get _safeTeacherId {
    if (_teacherId == null) return null;
    if (_teachers.isEmpty) return null;
    return _teachers.any((t) => t.id == _teacherId) ? _teacherId : null;
  }

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _name = TextEditingController(text: c?.name ?? '');
    _code = TextEditingController(text: c?.code ?? '');
    _semester = TextEditingController(text: c?.semester ?? '');
    _departmentId = c?.departmentId.isNotEmpty == true ? c!.departmentId : null;
    _teacherId = c?.teacherId;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final deps = await AcademicsService.instance.getDepartments();
      final teachers = await AccountsService.instance.getUsers(role: 'teacher');
      if (!mounted) return;
      setState(() {
        _departments = deps;
        _teachers = teachers;
        if (_departmentId != null && !deps.any((d) => d.id == _departmentId)) {
          _departmentId = null;
        }
        if (_teacherId != null && !teachers.any((t) => t.id == _teacherId)) {
          _teacherId = null;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departmentId == null || _departmentId!.isEmpty) {
      setState(() => _error = 'Department is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await AcademicsService.instance.updateCourse(
          widget.course!.id,
          name: _name.text.trim(),
          code: _code.text.trim(),
          departmentId: _departmentId,
          semester: _semester.text.trim(),
          teacherId: _teacherId,
        );
      } else {
        await AcademicsService.instance.createCourse(
          name: _name.text.trim(),
          code: _code.text.trim(),
          departmentId: _departmentId!,
          semester: _semester.text.trim(),
          teacherId: _teacherId,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Course' : 'Add Course'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Course name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _semester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _safeDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department *'),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _departmentId = v),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _safeTeacherId,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unassigned')),
                    ..._teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                  ],
                  onChanged: (v) => setState(() => _teacherId = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
