from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from academics.models import ClassSchedule, Course, Department, Enrollment
from accounts.permissions import IsAdmin, IsStudent, IsTeacher

from .models import AttendanceRecord, AttendanceSession
from .serializers import (
    AttendanceRecordSerializer,
    AttendanceSessionSerializer,
    CreateSessionSerializer,
    MarkAttendanceSerializer,
)

User = get_user_model()


class AttendanceSessionViewSet(viewsets.ModelViewSet):
    queryset = AttendanceSession.objects.select_related('course', 'teacher')
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['course', 'status']

    def get_serializer_class(self):
        if self.action == 'create':
            return CreateSessionSerializer
        return AttendanceSessionSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if user.role == 'teacher':
            return qs.filter(teacher=user)
        if user.role == 'student':
            return qs.filter(course__enrollments__student=user).distinct()
        return qs

    def get_permissions(self):
        if self.action == 'create':
            return [IsTeacher()]
        return super().get_permissions()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        session = serializer.save()
        return Response(
            AttendanceSessionSerializer(session).data, status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'])
    def close(self, request, pk=None):
        session = self.get_object()
        if session.teacher_id != request.user.id and request.user.role != 'admin':
            return Response({'detail': 'Not allowed.'}, status=status.HTTP_403_FORBIDDEN)
        session.close()
        return Response(AttendanceSessionSerializer(session).data)

    @action(detail=True, methods=['get'])
    def live_status(self, request, pk=None):
        session = self.get_object()
        # Auto expire if past expiry
        if session.status == AttendanceSession.STATUS_ACTIVE and session.is_expired:
            session.status = AttendanceSession.STATUS_EXPIRED
            session.save(update_fields=['status'])
        return Response(AttendanceSessionSerializer(session).data)


class MarkAttendanceView(APIView):
    permission_classes = [IsStudent]

    def post(self, request):
        serializer = MarkAttendanceSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        record = serializer.save()
        return Response(AttendanceRecordSerializer(record).data, status=status.HTTP_201_CREATED)


class AttendanceRecordViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AttendanceRecord.objects.select_related('student', 'course', 'session')
    serializer_class = AttendanceRecordSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['course', 'status', 'student']

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if user.role == 'student':
            return qs.filter(student=user)
        if user.role == 'teacher':
            return qs.filter(course__teacher=user)
        return qs


class MyAttendanceStatsView(APIView):
    """Student: overall %, present/absent counts and subject-wise breakdown."""
    permission_classes = [IsStudent]

    def get(self, request):
        student = request.user
        records = AttendanceRecord.objects.filter(student=student)
        total = records.count()
        present = records.filter(status=AttendanceRecord.STATUS_PRESENT).count()
        absent = total - present
        percentage = round((present / total) * 100, 1) if total else 0.0

        subject_wise = []
        course_ids = records.values_list('course', flat=True).distinct()
        for course in Course.objects.filter(id__in=course_ids):
            c_total = records.filter(course=course).count()
            c_present = records.filter(course=course, status=AttendanceRecord.STATUS_PRESENT).count()
            subject_wise.append({
                'course_id': str(course.id),
                'course_name': f'{course.name} ({course.code})',
                'percentage': round((c_present / c_total) * 100, 1) if c_total else 0.0,
                'present': c_present,
                'total': c_total,
            })

        return Response({
            'overall_percentage': percentage,
            'present': present,
            'absent': absent,
            'total': total,
            'subject_wise': subject_wise,
        })


class StudentDashboardView(APIView):
    permission_classes = [IsStudent]

    def get(self, request):
        student = request.user
        today_weekday = timezone.localtime().weekday()

        enrolled_course_ids = Enrollment.objects.filter(student=student).values_list('course', flat=True)
        today_schedules = ClassSchedule.objects.filter(
            course__in=enrolled_course_ids, weekday=today_weekday,
        ).select_related('course').order_by('start_time')

        upcoming = [{
            'course': f'{s.course.name} ({s.course.code})',
            'time': s.start_time.strftime('%I:%M %p'),
            'room': s.room,
        } for s in today_schedules]

        records = AttendanceRecord.objects.filter(student=student)
        total = records.count()
        present = records.filter(status=AttendanceRecord.STATUS_PRESENT).count()
        percentage = round((present / total) * 100, 1) if total else 0.0

        unread_notifications = student.notifications.filter(is_read=False).count()

        return Response({
            'attendance_percentage': percentage,
            'todays_classes_count': today_schedules.count(),
            'unread_notifications': unread_notifications,
            'upcoming_classes': upcoming,
        })


class TeacherDashboardView(APIView):
    permission_classes = [IsTeacher]

    def get(self, request):
        teacher = request.user
        today_weekday = timezone.localtime().weekday()

        teacher_course_ids = Course.objects.filter(teacher=teacher).values_list('id', flat=True)
        today_schedules = ClassSchedule.objects.filter(
            course__in=teacher_course_ids, weekday=today_weekday,
        ).select_related('course').order_by('start_time')

        schedule_data = [{
            'course': f'{s.course.name} ({s.course.code})',
            'time': f"{s.start_time.strftime('%I:%M %p')} - {s.end_time.strftime('%I:%M %p')}",
            'room': s.room,
        } for s in today_schedules]

        today_start = timezone.localtime().replace(hour=0, minute=0, second=0, microsecond=0)
        sessions_today = AttendanceSession.objects.filter(teacher=teacher, started_at__gte=today_start)
        records_today = AttendanceRecord.objects.filter(
            session__in=sessions_today,
        )
        present_today = records_today.filter(status=AttendanceRecord.STATUS_PRESENT).count()

        # naive "absent" = enrolled across today's sessions - present
        absent_today = 0
        for s in sessions_today:
            absent_today += max(s.total_enrolled - s.marked_count, 0)

        return Response({
            'todays_classes_count': today_schedules.count(),
            'attendance_sessions_today': sessions_today.count(),
            'present_students_today': present_today,
            'absent_students_today': absent_today,
            'todays_schedule': schedule_data,
        })


class AdminDashboardView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        total_students = User.objects.filter(role='student').count()
        total_teachers = User.objects.filter(role='teacher').count()
        total_departments = Department.objects.count()
        total_courses = Course.objects.count()

        today_start = timezone.localtime().replace(hour=0, minute=0, second=0, microsecond=0)
        records_today = AttendanceRecord.objects.filter(marked_at__gte=today_start)
        sessions_today = AttendanceSession.objects.filter(started_at__gte=today_start)
        active_sessions = AttendanceSession.objects.filter(status=AttendanceSession.STATUS_ACTIVE)

        total_expected_today = sum(s.total_enrolled for s in sessions_today) or 1
        present_today = records_today.filter(status=AttendanceRecord.STATUS_PRESENT).count()
        todays_attendance_pct = round((present_today / total_expected_today) * 100, 1) if total_expected_today else 0.0

        return Response({
            'total_students': total_students,
            'total_teachers': total_teachers,
            'total_departments': total_departments,
            'total_courses': total_courses,
            'todays_attendance_percentage': todays_attendance_pct,
            'active_sessions': active_sessions.count(),
        })


class AdminAnalyticsView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        records = AttendanceRecord.objects.all()
        total = records.count()
        present = records.filter(status=AttendanceRecord.STATUS_PRESENT).count()
        overall_pct = round((present / total) * 100, 1) if total else 0.0

        # Last 7 days trend
        trend = []
        today = timezone.localtime().date()
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            day_records = records.filter(marked_at__date=day)
            day_total = day_records.count()
            day_present = day_records.filter(status=AttendanceRecord.STATUS_PRESENT).count()
            pct = round((day_present / day_total) * 100, 1) if day_total else 0.0
            trend.append({'date': day.isoformat(), 'percentage': pct})

        department_wise = []
        for dept in Department.objects.all():
            dept_records = records.filter(course__department=dept)
            d_total = dept_records.count()
            d_present = dept_records.filter(status=AttendanceRecord.STATUS_PRESENT).count()
            department_wise.append({
                'department': dept.name,
                'percentage': round((d_present / d_total) * 100, 1) if d_total else 0.0,
            })

        return Response({
            'overall_percentage': overall_pct,
            'trend': trend,
            'department_wise': department_wise,
        })
