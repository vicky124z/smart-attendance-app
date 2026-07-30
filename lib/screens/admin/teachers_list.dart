import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/accounts_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/user_form_dialog.dart';

class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({super.key});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  bool _loading = true;
  String? _error;
  List<UserModel> _teachers = [];
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
      final list = await AccountsService.instance.getUsers(role: 'teacher', search: search);
      if (!mounted) return;
      setState(() {
        _teachers = list;
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

  Future<void> _openForm({UserModel? teacher}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(role: 'teacher', user: teacher),
    );
    if (result == true) _load();
  }

  Future<void> _delete(UserModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete teacher?'),
        content: Text('Remove ${t.name}? This cannot be undone.'),
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
      await AccountsService.instance.deleteUser(t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher deleted')));
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
      appBar: AppBar(title: const Text('Teachers')),
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
                hintText: 'Search teachers...',
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
                    : _teachers.isEmpty
                        ? const Center(
                            child: Text('No teachers found.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _teachers.length,
                            itemBuilder: (context, index) {
                              final t = _teachers[index];
                              final parts = t.name.split(' ');
                              final initial = parts.isNotEmpty ? parts.last[0].toUpperCase() : '?';
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
                                      backgroundColor: const Color(0xFFD1FAE5),
                                      child: Text(initial,
                                          style: const TextStyle(
                                              color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.name,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          Text(
                                            [
                                              if (t.department != null && t.department!.isNotEmpty) t.department!,
                                              t.email,
                                            ].join(' · '),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _openForm(teacher: t);
                                        if (v == 'delete') _delete(t);
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
