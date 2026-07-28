class AttendanceSessionModel {
  final String id;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String teacherName;
  final String room;
  final String sessionType;
  final int durationMinutes;
  final bool gpsVerification;
  final bool faceRecognition;
  final String code;
  final String qrPayload;
  final String status;
  final bool isActive;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int markedCount;
  final int totalEnrolled;

  AttendanceSessionModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.teacherName,
    required this.room,
    required this.sessionType,
    required this.durationMinutes,
    required this.gpsVerification,
    required this.faceRecognition,
    required this.code,
    required this.qrPayload,
    required this.status,
    required this.isActive,
    required this.startedAt,
    required this.expiresAt,
    required this.markedCount,
    required this.totalEnrolled,
  });

  Duration get remaining => expiresAt.difference(DateTime.now());

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id']?.toString() ?? '',
      courseId: json['course']?.toString() ?? '',
      courseName: json['course_name'] ?? '',
      courseCode: json['course_code'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      room: json['room'] ?? '',
      sessionType: json['session_type'] ?? 'Lecture',
      durationMinutes: json['duration_minutes'] ?? 60,
      gpsVerification: json['gps_verification'] ?? false,
      faceRecognition: json['face_recognition'] ?? false,
      code: json['code'] ?? '',
      qrPayload: json['qr_payload'] ?? '',
      status: json['status'] ?? 'active',
      isActive: json['is_active'] ?? false,
      startedAt: DateTime.tryParse(json['started_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      markedCount: json['marked_count'] ?? 0,
      totalEnrolled: json['total_enrolled'] ?? 0,
    );
  }
}

class AttendanceRecordModel {
  final String id;
  final String sessionId;
  final String studentName;
  final String courseName;
  final String courseCode;
  final String status;
  final DateTime markedAt;

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentName,
    required this.courseName,
    required this.courseCode,
    required this.status,
    required this.markedAt,
  });

  bool get isPresent => status == 'present';

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['session']?.toString() ?? '',
      studentName: json['student_name'] ?? '',
      courseName: json['course_name'] ?? '',
      courseCode: json['course_code'] ?? '',
      status: json['status'] ?? 'absent',
      markedAt: DateTime.tryParse(json['marked_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class SubjectAttendanceModel {
  final String courseId;
  final String courseName;
  final double percentage;
  final int present;
  final int total;

  SubjectAttendanceModel({
    required this.courseId,
    required this.courseName,
    required this.percentage,
    required this.present,
    required this.total,
  });

  factory SubjectAttendanceModel.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceModel(
      courseId: json['course_id']?.toString() ?? '',
      courseName: json['course_name'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      present: json['present'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class MyAttendanceStats {
  final double overallPercentage;
  final int present;
  final int absent;
  final int total;
  final List<SubjectAttendanceModel> subjectWise;

  MyAttendanceStats({
    required this.overallPercentage,
    required this.present,
    required this.absent,
    required this.total,
    required this.subjectWise,
  });

  factory MyAttendanceStats.fromJson(Map<String, dynamic> json) {
    return MyAttendanceStats(
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0.0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      total: json['total'] ?? 0,
      subjectWise: (json['subject_wise'] as List<dynamic>? ?? [])
          .map((e) => SubjectAttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
