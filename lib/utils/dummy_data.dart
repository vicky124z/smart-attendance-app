import '../models/user_model.dart';

class DummyData {
  static UserModel currentUser = UserModel(
    id: '1B23CS101',
    name: 'Rahul Sharma',
    email: 'rahul@gmail.com',
    phone: '+91 98765 43210',
    role: UserRole.student,
    department: 'Computer Science',
    semester: 'Semester 4',
    studentId: '1B23CS101',
    attendancePercentage: 87.4,
  );

  static List<Map<String, dynamic>> students = [
    {'name': 'Rahul Sharma', 'id': '1B23CS101', 'dept': 'CSE - Sem 4'},
    {'name': 'Priya Patel', 'id': '1B23CS102', 'dept': 'CSE - Sem 4'},
    {'name': 'Aman Verma', 'id': '1B23CS103', 'dept': 'CSE - Sem 4'},
    {'name': 'Neha Singh', 'id': '1B23CS104', 'dept': 'CSE - Sem 4'},
    {'name': 'Rohan Gupta', 'id': '1B23CS105', 'dept': 'CSE - Sem 4'},
  ];

  static List<Map<String, dynamic>> teachers = [
    {'name': 'Mr. Arjun Sharma', 'dept': 'Computer Science'},
    {'name': 'Ms. Kavya Nair', 'dept': 'Information Technology'},
    {'name': 'Mr. Rahul Joshi', 'dept': 'Electronics'},
    {'name': 'Ms. Sneha Reddy', 'dept': 'Computer Science'},
  ];

  static List<Map<String, dynamic>> departments = [
    {'name': 'Computer Science', 'students': 620, 'teachers': 28},
    {'name': 'Information Technology', 'students': 540, 'teachers': 16},
    {'name': 'Electronics', 'students': 210, 'teachers': 12},
    {'name': 'Mechanical', 'students': 180, 'teachers': 10},
  ];

  static List<Map<String, dynamic>> courses = [
    {'name': 'Data Structures (CS201)', 'semester': 'Semester 4'},
    {'name': 'DBMS (CS303)', 'semester': 'Semester 6'},
    {'name': 'Operating Systems (CS402)', 'semester': 'Semester 4'},
    {'name': 'Artificial Intelligence (CS503)', 'semester': 'Semester 6'},
  ];

  static List<Map<String, dynamic>> attendanceHistory = [
    {'date': '20 May 2024', 'course': 'Data Structures (CS201)', 'time': '09:15 AM', 'status': 'Present'},
    {'date': '20 May 2024', 'course': 'DBMS (CS303)', 'time': '11:00 AM', 'status': 'Present'},
    {'date': '19 May 2024', 'course': 'OS (CS402)', 'time': '02:00 PM', 'status': 'Absent'},
    {'date': '18 May 2024', 'course': 'AI (CS503)', 'time': '04:10 PM', 'status': 'Present'},
    {'date': '17 May 2024', 'course': 'Data Structures (CS201)', 'time': '09:00 AM', 'status': 'Present'},
  ];

  static List<Map<String, dynamic>> notifications = [
    {
      'type': 'attendance',
      'title': 'Attendance Marked',
      'subtitle': 'Your attendance marked for Data Structures (CS201)',
      'time': '10:15 AM',
      'icon': 'check',
    },
    {
      'type': 'session',
      'title': 'Session Started',
      'subtitle': 'DBMS (CS303) session has been started by Mr. Arjun',
      'time': '09:00 AM',
      'icon': 'play',
    },
    {
      'type': 'warning',
      'title': 'Low Attendance Warning',
      'subtitle': 'Your attendance is 76% in Database Systems (CS303)',
      'time': 'Yesterday',
      'icon': 'warning',
    },
    {
      'type': 'announcement',
      'title': 'New Announcement',
      'subtitle': 'Department meeting on 25 May 2024 at 2:00 PM',
      'time': 'Yesterday',
      'icon': 'announcement',
    },
    {
      'type': 'session',
      'title': 'Session Closed',
      'subtitle': 'Data Structures (CS201) session has been closed',
      'time': '22 May',
      'icon': 'close',
    },
  ];

  static List<Map<String, dynamic>> todaySchedule = [
    {'course': 'Data Structures (CS201)', 'time': '09:00 AM - 10:00 AM', 'room': 'Room 204', 'color': 0xFF3B82F6},
    {'course': 'DBMS (CS303)', 'time': '11:00 AM - 12:00 PM', 'room': 'Room 206', 'color': 0xFF8B5CF6},
    {'course': 'OS (CS402)', 'time': '02:00 PM - 03:00 PM', 'room': 'Room 208', 'color': 0xFFF59E0B},
    {'course': 'AI (CS503)', 'time': '04:00 PM - 05:00 PM', 'room': 'Room 301', 'color': 0xFFEF4444},
  ];

  static List<Map<String, dynamic>> upcomingClasses = [
    {'course': 'Data Structures (CS201)', 'time': '09:00 AM', 'room': 'Room 204'},
    {'course': 'DBMS (CS303)', 'time': '11:00 AM', 'room': 'Room 206'},
    {'course': 'OS (CS402)', 'time': '02:00 PM', 'room': 'Room 208'},
    {'course': 'AI (CS503)', 'time': '04:00 PM', 'room': 'Room 301'},
  ];
}
