import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/accounts_service.dart';

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
      final students = await AccountsService.instance.getUsers(role: 'student', search: search);
      setState(() => _students = students);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(search: value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Students'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add student flow coming soon.')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
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
                              ElevatedButton(onPressed: () => _load(), child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _students.isEmpty
                        ? const Center(
                            child: Text('No students found.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(),
                            child: ListView.builder(
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
                                        child: Text(
                                          initial,
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            Text(
                                              s.studentId ?? '-',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(s.department ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
