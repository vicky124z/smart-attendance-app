import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/accounts_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/user_form_dialog.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  bool _loading = true;
  String? _error;
  List<UserModel> _students = [];
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
      final list = await AccountsService.instance.getUsers(role: 'student', search: search);
      if (!mounted) return;
      setState(() {
        _students = list;
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

  Future<void> _openForm({UserModel? student}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(role: 'student', user: student),
    );
    if (result == true) _load();
  }

  Future<void> _delete(UserModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${s.name}? This cannot be undone.'),
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
      await AccountsService.instance.deleteUser(s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted')));
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
      appBar: AppBar(title: const Text('Students')),
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
                hintText: 'Search students...',
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
                            ElevatedButton(onPressed: () => _load(), child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _students.isEmpty
                        ? const Center(
                            child: Text('No students found.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final s = _students[index];
                              final initial = s.name.isNotEmpty ? s.name[0].toUpperCase() : '?';
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
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      child: Text(initial,
                                          style: const TextStyle(
                                              color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          Text(
                                            [
                                              if (s.studentId != null && s.studentId!.isNotEmpty) s.studentId!,
                                              s.email,
                                            ].join(' · '),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _openForm(student: s);
                                        if (v == 'delete') _delete(s);
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

