import '../models/attendance_model.dart';
import 'api_client.dart';

class AttendanceService {
  AttendanceService._internal();
  static final AttendanceService instance = AttendanceService._internal();

  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> studentDashboard() async {
    return await _api.get('/attendance/dashboard/student/') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> teacherDashboard() async {
    return await _api.get('/attendance/dashboard/teacher/') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> adminDashboard() async {
    return await _api.get('/attendance/dashboard/admin/') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> adminAnalytics() async {
    return await _api.get('/attendance/analytics/admin/') as Map<String, dynamic>;
  }

  Future<MyAttendanceStats> myStats() async {
    final data = await _api.get('/attendance/my-stats/') as Map<String, dynamic>;
    return MyAttendanceStats.fromJson(data);
  }

  Future<List<AttendanceRecordModel>> myHistory() async {
    final data = await _api.get('/attendance/records/');
    final results = (data is Map<String, dynamic>) ? data['results'] as List<dynamic> : data as List<dynamic>;
    return results.map((e) => AttendanceRecordModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AttendanceSessionModel> createSession({
    required String courseId,
    required String room,
    required String sessionType,
    required int durationMinutes,
    required bool gpsVerification,
    required bool faceRecognition,
  }) async {
    final data = await _api.post('/attendance/sessions/', body: {
      'course': courseId,
      'room': room,
      'session_type': sessionType,
      'duration_minutes': durationMinutes,
      'gps_verification': gpsVerification,
      'face_recognition': faceRecognition,
    }) as Map<String, dynamic>;
    return AttendanceSessionModel.fromJson(data);
  }

  Future<AttendanceSessionModel> sessionStatus(String sessionId) async {
    final data = await _api.get('/attendance/sessions/$sessionId/live_status/') as Map<String, dynamic>;
    return AttendanceSessionModel.fromJson(data);
  }

  Future<AttendanceSessionModel> closeSession(String sessionId) async {
    final data = await _api.post('/attendance/sessions/$sessionId/close/') as Map<String, dynamic>;
    return AttendanceSessionModel.fromJson(data);
  }

  /// Mark attendance from a scanned QR payload ("sessionId:code") or raw code.
  Future<AttendanceRecordModel> markAttendance(String code, {double? lat, double? lng}) async {
    final data = await _api.post('/attendance/mark/', body: {
      'code': code,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    }) as Map<String, dynamic>;
    return AttendanceRecordModel.fromJson(data);
  }
}
