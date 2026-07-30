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

  /// Fetch attendance records for export (JSON). Role-scoped on the server.
  Future<List<Map<String, dynamic>>> exportReport({
    String? courseId,
    String? departmentId,
    String? studentId,
    String? from,
    String? to,
  }) async {
    final data = await _api.get('/attendance/export/', query: {
      'format': 'json',
      if (courseId != null && courseId.isNotEmpty) 'course': courseId,
      if (departmentId != null && departmentId.isNotEmpty) 'department': departmentId,
      if (studentId != null && studentId.isNotEmpty) 'student': studentId,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    }) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];
    return results.cast<Map<String, dynamic>>();
  }

  /// Build a CSV string from export rows.
  static String rowsToCsv(List<Map<String, dynamic>> rows) {
    const headers = [
      'Student Name', 'Student Email', 'Student Code',
      'Course Name', 'Course Code', 'Department',
      'Status', 'Marked At', 'Session ID',
    ];
    final buf = StringBuffer();
    buf.writeln(headers.join(','));
    for (final r in rows) {
      String esc(dynamic v) {
        final s = (v ?? '').toString().replaceAll('"', '""');
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"$s"';
        }
        return s;
      }
      buf.writeln([
        esc(r['student_name']),
        esc(r['student_email']),
        esc(r['student_code']),
        esc(r['course_name']),
        esc(r['course_code']),
        esc(r['department']),
        esc(r['status']),
        esc(r['marked_at']),
        esc(r['session_id']),
      ].join(','));
    }
    return buf.toString();
  }
}
