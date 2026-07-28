import random
from datetime import time, timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from academics.models import ClassSchedule, Course, Department, Enrollment
from attendance.models import AttendanceRecord, AttendanceSession
from notifications.models import Notification

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds the database with demo Departments, Courses, Users, Enrollments, Schedules and Attendance history.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--flush', action='store_true',
            help='Delete existing demo-generated data before seeding.',
        )

    def handle(self, *args, **options):
        if options['flush']:
            self.stdout.write('Flushing existing data...')
            AttendanceRecord.objects.all().delete()
            AttendanceSession.objects.all().delete()
            Notification.objects.all().delete()
            Enrollment.objects.all().delete()
            ClassSchedule.objects.all().delete()
            Course.objects.all().delete()
            Department.objects.all().delete()
            User.objects.filter(is_superuser=False).delete()

        self.stdout.write('Seeding departments...')
        dept_data = [
            ('Computer Science', 'CSE'),
            ('Information Technology', 'IT'),
            ('Electronics', 'ECE'),
            ('Mechanical', 'MECH'),
        ]
        departments = {}
        for name, code in dept_data:
            dept, _ = Department.objects.get_or_create(name=name, defaults={'code': code})
            departments[code] = dept

        self.stdout.write('Seeding admin user...')
        admin, created = User.objects.get_or_create(
            email='admin@smartattendance.app',
            defaults=dict(
                username='admin',
                first_name='System',
                last_name='Admin',
                role='admin',
                is_staff=True,
                is_superuser=True,
                phone='+91 90000 00001',
            ),
        )
        if created:
            admin.set_password('Admin@123')
            admin.save()

        self.stdout.write('Seeding teachers...')
        teacher_data = [
            ('Arjun', 'Sharma', 'arjun.sharma@smartattendance.app', 'CSE', 'T-1001'),
            ('Kavya', 'Nair', 'kavya.nair@smartattendance.app', 'IT', 'T-1002'),
            ('Rahul', 'Joshi', 'rahul.joshi@smartattendance.app', 'ECE', 'T-1003'),
            ('Sneha', 'Reddy', 'sneha.reddy@smartattendance.app', 'CSE', 'T-1004'),
        ]
        teachers = {}
        for first, last, email, dept_code, emp_code in teacher_data:
            t, created = User.objects.get_or_create(
                email=email,
                defaults=dict(
                    username=email.split('@')[0],
                    first_name=first,
                    last_name=last,
                    role='teacher',
                    department=departments[dept_code],
                    employee_code=emp_code,
                    phone='+91 90000 00002',
                ),
            )
            if created:
                t.set_password('Teacher@123')
                t.save()
            teachers[emp_code] = t

        self.stdout.write('Seeding courses...')
        course_data = [
            ('Data Structures', 'CS201', 'CSE', 'Semester 4', 'T-1001'),
            ('DBMS', 'CS303', 'CSE', 'Semester 6', 'T-1004'),
            ('Operating Systems', 'CS402', 'CSE', 'Semester 4', 'T-1001'),
            ('Artificial Intelligence', 'CS503', 'CSE', 'Semester 6', 'T-1004'),
        ]
        courses = {}
        for name, code, dept_code, semester, emp_code in course_data:
            c, _ = Course.objects.get_or_create(
                code=code,
                defaults=dict(
                    name=name,
                    department=departments[dept_code],
                    semester=semester,
                    teacher=teachers[emp_code],
                ),
            )
            courses[code] = c

        self.stdout.write('Seeding class schedules (today\'s timetable, Mon-Fri)...')
        schedule_data = [
            ('CS201', '09:00', '10:00', 'Room 204'),
            ('CS303', '11:00', '12:00', 'Room 206'),
            ('CS402', '14:00', '15:00', 'Room 208'),
            ('CS503', '16:00', '17:00', 'Room 301'),
        ]
        for code, start, end, room in schedule_data:
            sh, sm = map(int, start.split(':'))
            eh, em = map(int, end.split(':'))
            for weekday in range(0, 6):  # Mon-Sat
                ClassSchedule.objects.get_or_create(
                    course=courses[code], weekday=weekday,
                    defaults=dict(start_time=time(sh, sm), end_time=time(eh, em), room=room),
                )

        self.stdout.write('Seeding students...')
        student_data = [
            ('Rahul', 'Sharma', 'rahul.sharma@smartattendance.app', 'CSE', '1B23CS101'),
            ('Priya', 'Patel', 'priya.patel@smartattendance.app', 'CSE', '1B23CS102'),
            ('Aman', 'Verma', 'aman.verma@smartattendance.app', 'CSE', '1B23CS103'),
            ('Neha', 'Singh', 'neha.singh@smartattendance.app', 'CSE', '1B23CS104'),
            ('Rohan', 'Gupta', 'rohan.gupta@smartattendance.app', 'CSE', '1B23CS105'),
        ]
        students = []
        for first, last, email, dept_code, sid in student_data:
            s, created = User.objects.get_or_create(
                email=email,
                defaults=dict(
                    username=email.split('@')[0],
                    first_name=first,
                    last_name=last,
                    role='student',
                    department=departments[dept_code],
                    student_code=sid,
                    semester='Semester 4',
                    phone='+91 98765 43210',
                ),
            )
            if created:
                s.set_password('Student@123')
                s.save()
            students.append(s)

        self.stdout.write('Enrolling students into courses...')
        for s in students:
            for code in ['CS201', 'CS303', 'CS402', 'CS503']:
                Enrollment.objects.get_or_create(student=s, course=courses[code])

        self.stdout.write('Generating attendance history (last 20 days)...')
        random.seed(42)
        today = timezone.localtime().date()
        for days_ago in range(20, 0, -1):
            day = today - timedelta(days=days_ago)
            if day.weekday() == 6:  # skip Sundays
                continue
            for code, course in courses.items():
                session = AttendanceSession.objects.create(
                    course=course,
                    teacher=course.teacher,
                    room='Room 204',
                    session_type='Lecture',
                    duration_minutes=60,
                    status=AttendanceSession.STATUS_CLOSED,
                    expires_at=timezone.now(),
                )
                session.started_at = timezone.make_aware(
                    timezone.datetime.combine(day, time(9, 0))
                )
                session.closed_at = session.started_at + timedelta(minutes=60)
                session.expires_at = session.closed_at
                session.save(update_fields=['started_at', 'closed_at', 'expires_at'])

                for s in students:
                    present = random.random() < 0.85
                    if present:
                        record = AttendanceRecord.objects.create(
                            session=session, student=s, course=course,
                            status=AttendanceRecord.STATUS_PRESENT,
                        )
                        record.marked_at = session.started_at + timedelta(minutes=random.randint(0, 15))
                        record.save(update_fields=['marked_at'])
                    else:
                        AttendanceRecord.objects.create(
                            session=session, student=s, course=course,
                            status=AttendanceRecord.STATUS_ABSENT,
                        )

        self.stdout.write('Seeding sample notifications for first student...')
        sample_student = students[0]
        notif_data = [
            ('attendance', 'Attendance Marked', 'Your attendance marked for Data Structures (CS201)', False, False),
            ('session', 'Session Started', 'DBMS (CS303) session has been started by Mr. Arjun', False, False),
            ('warning', 'Low Attendance Warning', 'Your attendance is below 80% in Operating Systems (CS402)', False, True),
            ('announcement', 'New Announcement', 'Department meeting on 25 May 2024 at 2:00 PM', True, False),
            ('session', 'Session Closed', 'Data Structures (CS201) session has been closed', True, False),
        ]
        for n_type, title, subtitle, is_read, important in notif_data:
            Notification.objects.get_or_create(
                recipient=sample_student, title=title,
                defaults=dict(type=n_type, subtitle=subtitle, is_read=is_read, is_important=important),
            )

        self.stdout.write(self.style.SUCCESS('Demo data seeded successfully!'))
        self.stdout.write('')
        self.stdout.write('Demo credentials:')
        self.stdout.write('  Admin:   admin@smartattendance.app / Admin@123')
        self.stdout.write('  Teacher: arjun.sharma@smartattendance.app / Teacher@123')
        self.stdout.write('  Student: rahul.sharma@smartattendance.app / Student@123')
