import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'utils/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/student/student_dashboard.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const SmartAttendanceApp(),
    ),
  );
}

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/role': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/teacher': (context) => const TeacherDashboard(),
        '/student': (context) => const StudentDashboard(),
      },
    );
  }
}
