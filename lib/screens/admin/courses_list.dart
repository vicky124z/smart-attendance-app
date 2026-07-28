import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/course_model.dart';
import '../../services/academics_service.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  bool _loading = true;
  String? _error;
  List<CourseModel> _courses = [];
  String _query = '';
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await AcademicsService.instance.getCourses();
      setState(() => _courses = courses);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _query = value));
  }

  List<CourseModel> get _filtered {
    if (_query.trim().isEmpty) return _courses;
    final q = _query.toLowerCase();
    return _courses.where((c) => c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Courses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add course flow coming soon.')),
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
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text('No courses found.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final c = _filtered[index];
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
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F3FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.menu_book, color: AppColors.purple, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            Text(
                                              c.semester.isNotEmpty ? c.semester : c.departmentName,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
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
