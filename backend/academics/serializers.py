from rest_framework import serializers

from .models import ClassSchedule, Course, Department, Enrollment


class DepartmentSerializer(serializers.ModelSerializer):
    student_count = serializers.IntegerField(read_only=True)
    teacher_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Department
        fields = ['id', 'name', 'code', 'student_count', 'teacher_count', 'created_at']


class ClassScheduleSerializer(serializers.ModelSerializer):
    weekday_display = serializers.CharField(source='get_weekday_display', read_only=True)

    class Meta:
        model = ClassSchedule
        fields = ['id', 'course', 'weekday', 'weekday_display', 'start_time', 'end_time', 'room']


class CourseSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    teacher_name = serializers.SerializerMethodField()
    schedules = ClassScheduleSerializer(many=True, read_only=True)
    enrolled_count = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = [
            'id', 'name', 'code', 'department', 'department_name', 'semester',
            'teacher', 'teacher_name', 'schedules', 'enrolled_count', 'created_at',
        ]

    def get_teacher_name(self, obj):
        return obj.teacher.get_full_name() if obj.teacher else None

    def get_enrolled_count(self, obj):
        return obj.enrollments.count()


class EnrollmentSerializer(serializers.ModelSerializer):
    course_detail = CourseSerializer(source='course', read_only=True)
    student_name = serializers.SerializerMethodField()

    class Meta:
        model = Enrollment
        fields = ['id', 'student', 'student_name', 'course', 'course_detail', 'created_at']

    def get_student_name(self, obj):
        return obj.student.get_full_name() or obj.student.username
