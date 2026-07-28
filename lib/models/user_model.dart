enum UserRole { administrator, teacher, student }

UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'admin':
      return UserRole.administrator;
    case 'teacher':
      return UserRole.teacher;
    case 'student':
    default:
      return UserRole.student;
  }
}

String userRoleToApiString(UserRole role) {
  switch (role) {
    case UserRole.administrator:
      return 'admin';
    case UserRole.teacher:
      return 'teacher';
    case UserRole.student:
      return 'student';
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? department;
  final String? departmentId;
  final String? semester;
  final String? studentId;
  final double attendancePercentage;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.department,
    this.departmentId,
    this.semester,
    this.studentId,
    this.attendancePercentage = 0.0,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name']
          : (json['username'] ?? json['email'] ?? ''),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: userRoleFromString(json['role']),
      department: json['department_name'],
      departmentId: json['department']?.toString(),
      semester: json['semester'],
      studentId: (json['display_id'] as String?)?.isNotEmpty == true
          ? json['display_id']
          : json['student_code'],
      attendancePercentage: (json['attendance_percentage'] is num)
          ? (json['attendance_percentage'] as num).toDouble()
          : 0.0,
      avatarUrl: json['avatar_url'],
    );
  }
}
