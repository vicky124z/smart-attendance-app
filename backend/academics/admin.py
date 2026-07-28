from django.contrib import admin

from .models import ClassSchedule, Course, Department, Enrollment


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'student_count', 'teacher_count')
    search_fields = ('name', 'code')


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'department', 'teacher', 'semester')
    list_filter = ('department', 'semester')
    search_fields = ('name', 'code')


@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ('student', 'course', 'created_at')
    search_fields = ('student__username', 'course__name')


@admin.register(ClassSchedule)
class ClassScheduleAdmin(admin.ModelAdmin):
    list_display = ('course', 'weekday', 'start_time', 'end_time', 'room')
    list_filter = ('weekday',)
