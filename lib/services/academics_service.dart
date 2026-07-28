import '../models/course_model.dart';
import 'api_client.dart';

class AcademicsService {
  AcademicsService._internal();
  static final AcademicsService instance = AcademicsService._internal();

  final _api = ApiClient.instance;

  Future<List<CourseModel>> getCourses() async {
    final data = await _api.get('/academics/courses/');
    final results = (data is Map<String, dynamic>) ? data['results'] as List<dynamic> : data as List<dynamic>;
    return results.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DepartmentModel>> getDepartments() async {
    final data = await _api.get('/academics/departments/');
    final results = (data is Map<String, dynamic>) ? data['results'] as List<dynamic> : data as List<dynamic>;
    return results.map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
