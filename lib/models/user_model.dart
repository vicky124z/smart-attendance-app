enum UserRole { administrator, teacher, student }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? department;
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
    this.semester,
    this.studentId,
    this.attendancePercentage = 0.0,
    this.avatarUrl,
  });
}
