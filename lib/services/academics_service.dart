import '../models/course_model.dart';
import 'api_client.dart';

class AcademicsService {
  AcademicsService._();
  static final AcademicsService instance = AcademicsService._();

  final _api = ApiClient.instance;

  Future<List<CourseModel>> getCourses({String? search}) async {
    final data = await _api.get('/academics/courses/', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final list = data is Map ? (data['results'] as List? ?? []) : data as List;
    return list.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DepartmentModel>> getDepartments({String? search}) async {
    final data = await _api.get('/academics/departments/', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final list = data is Map ? (data['results'] as List? ?? []) : data as List;
    return list.map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DepartmentModel> createDepartment({required String name, required String code}) async {
    final data = await _api.post('/academics/departments/', body: {
      'name': name,
      'code': code,
    }) as Map<String, dynamic>;
    return DepartmentModel.fromJson(data);
  }

  Future<DepartmentModel> updateDepartment(String id, {required String name, required String code}) async {
    final data = await _api.patch('/academics/departments/$id/', body: {
      'name': name,
      'code': code,
    }) as Map<String, dynamic>;
    return DepartmentModel.fromJson(data);
  }

  Future<void> deleteDepartment(String id) async {
    await _api.delete('/academics/departments/$id/');
  }

  Future<CourseModel> createCourse({
    required String name,
    required String code,
    required String departmentId,
    String semester = '',
    String? teacherId,
  }) async {
    final data = await _api.post('/academics/courses/', body: {
      'name': name,
      'code': code,
      'department': departmentId,
      if (semester.isNotEmpty) 'semester': semester,
      if (teacherId != null && teacherId.isNotEmpty) 'teacher': teacherId,
    }) as Map<String, dynamic>;
    return CourseModel.fromJson(data);
  }

  Future<CourseModel> updateCourse(
    String id, {
    String? name,
    String? code,
    String? departmentId,
    String? semester,
    String? teacherId,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (departmentId != null) 'department': departmentId,
      if (semester != null) 'semester': semester,
      if (teacherId != null) 'teacher': teacherId.isEmpty ? null : teacherId,
    };
    final data = await _api.patch('/academics/courses/$id/', body: body) as Map<String, dynamic>;
    return CourseModel.fromJson(data);
  }

  Future<void> deleteCourse(String id) async {
    await _api.delete('/academics/courses/$id/');
  }
}
