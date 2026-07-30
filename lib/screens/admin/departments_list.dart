import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/course_model.dart';
import '../../services/academics_service.dart';
import '../../services/api_exception.dart';

class DepartmentsListScreen extends StatefulWidget {
  const DepartmentsListScreen({super.key});

  @override
  State<DepartmentsListScreen> createState() => _DepartmentsListScreenState();
}

class _DepartmentsListScreenState extends State<DepartmentsListScreen> {
  bool _loading = true;
  String? _error;
  List<DepartmentModel> _items = [];

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
      final list = await AcademicsService.instance.getDepartments();
      if (!mounted) return;
      setState(() {
        _items = list;
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

  Future<void> _openForm({DepartmentModel? dept}) async {
    final nameCtrl = TextEditingController(text: dept?.name ?? '');
    final codeCtrl = TextEditingController(text: dept?.code ?? '');
    final formKey = GlobalKey<FormState>();
    String? error;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(dept == null ? 'Add Department' : 'Edit Department'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        if (dept == null) {
                          await AcademicsService.instance.createDepartment(
                            name: nameCtrl.text.trim(),
                            code: codeCtrl.text.trim(),
                          );
                        } else {
                          await AcademicsService.instance.updateDepartment(
                            dept.id,
                            name: nameCtrl.text.trim(),
                            code: codeCtrl.text.trim(),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } on ApiException catch (e) {
                        setLocal(() {
                          error = e.message;
                          saving = false;
                        });
                      } catch (e) {
                        setLocal(() {
                          error = e.toString();
                          saving = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(dept == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    codeCtrl.dispose();
    if (result == true) _load();
  }

  Future<void> _delete(DepartmentModel d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text('Remove ${d.name}?'),
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
      await AcademicsService.instance.deleteDepartment(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted')));
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
      appBar: AppBar(title: const Text('Departments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final d = _items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  '${d.code}  ·  Students: ${d.studentCount}  ·  Teachers: ${d.teacherCount}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openForm(dept: d);
                              if (v == 'delete') _delete(d);
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
    );
  }
}
