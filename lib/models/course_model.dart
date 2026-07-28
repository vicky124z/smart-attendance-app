class ClassScheduleModel {
  final String id;
  final String courseId;
  final int weekday;
  final String weekdayDisplay;
  final String startTime;
  final String endTime;
  final String room;

  ClassScheduleModel({
    required this.id,
    required this.courseId,
    required this.weekday,
    required this.weekdayDisplay,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) {
    return ClassScheduleModel(
      id: json['id']?.toString() ?? '',
      courseId: json['course']?.toString() ?? '',
      weekday: json['weekday'] ?? 0,
      weekdayDisplay: json['weekday_display'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      room: json['room'] ?? '',
    );
  }
}

class CourseModel {
  final String id;
  final String name;
  final String code;
  final String departmentId;
  final String departmentName;
  final String semester;
  final String? teacherId;
  final String? teacherName;
  final int enrolledCount;
  final List<ClassScheduleModel> schedules;

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.departmentId,
    required this.departmentName,
    required this.semester,
    this.teacherId,
    this.teacherName,
    this.enrolledCount = 0,
    this.schedules = const [],
  });

  String get displayName => '$name ($code)';

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      departmentId: json['department']?.toString() ?? '',
      departmentName: json['department_name'] ?? '',
      semester: json['semester'] ?? '',
      teacherId: json['teacher']?.toString(),
      teacherName: json['teacher_name'],
      enrolledCount: json['enrolled_count'] ?? 0,
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map((e) => ClassScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DepartmentModel {
  final String id;
  final String name;
  final String code;
  final int studentCount;
  final int teacherCount;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    this.studentCount = 0,
    this.teacherCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      studentCount: json['student_count'] ?? 0,
      teacherCount: json['teacher_count'] ?? 0,
    );
  }
}
