import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../services/accounts_service.dart';
import '../services/academics_service.dart';
import '../services/api_exception.dart';

/// Shared create/edit form for student or teacher.
class UserFormDialog extends StatefulWidget {
  final String role; // student | teacher
  final UserModel? user;

  const UserFormDialog({super.key, required this.role, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _code;
  late final TextEditingController _semester;
  late final TextEditingController _password;
  String? _departmentId;
  List<DepartmentModel> _departments = [];
  bool _depsLoaded = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.user != null;
  bool get _isStudent => widget.role == 'student';

  /// Only pass a value the dropdown knows about (avoids Flutter assert).
  String? get _safeDepartmentId {
    if (_departmentId == null) return null;
    if (!_depsLoaded) return null;
    final match = _departments.where((d) => d.id == _departmentId);
    return match.isEmpty ? null : _departmentId;
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _code = TextEditingController(text: u?.studentId ?? '');
    _semester = TextEditingController(text: u?.semester ?? '');
    _password = TextEditingController();
    _departmentId = u?.departmentId;
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final deps = await AcademicsService.instance.getDepartments();
      if (!mounted) return;
      setState(() {
        _departments = deps;
        _depsLoaded = true;
        // Drop stale id if department was deleted
        if (_departmentId != null &&
            !deps.any((d) => d.id == _departmentId)) {
          _departmentId = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _depsLoaded = true);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _code.dispose();
    _semester.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await AccountsService.instance.updateUser(
          widget.user!.id,
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          departmentId: _departmentId,
          semester: _isStudent ? _semester.text.trim() : null,
          studentCode: _isStudent ? _code.text.trim() : null,
          employeeCode: !_isStudent ? _code.text.trim() : null,
          password: _password.text.trim().isEmpty ? null : _password.text.trim(),
          role: widget.role,
        );
      } else {
        await AccountsService.instance.createUser(
          name: _name.text.trim(),
          email: _email.text.trim(),
          role: widget.role,
          password: _password.text.trim().isEmpty ? 'changeme123' : _password.text.trim(),
          phone: _phone.text.trim(),
          departmentId: _departmentId,
          semester: _isStudent ? _semester.text.trim() : '',
          studentCode: _isStudent ? _code.text.trim() : '',
          employeeCode: !_isStudent ? _code.text.trim() : '',
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
    final title = _isEdit
        ? (_isStudent ? 'Edit Student' : 'Edit Teacher')
        : (_isStudent ? 'Add Student' : 'Add Teacher');
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                ),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _code,
                  decoration: InputDecoration(
                    labelText: _isStudent ? 'Student code' : 'Employee code',
                  ),
                ),
                if (_isStudent)
                  TextFormField(
                    controller: _semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                  ),
                DropdownButtonFormField<String?>(
                  initialValue: _safeDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ..._departments.map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _departmentId = v),
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'New password (optional)' : 'Password',
                    helperText: _isEdit ? null : 'Defaults to changeme123 if empty',
                  ),
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
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
