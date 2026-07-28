from django.contrib import admin

from .models import AttendanceRecord, AttendanceSession


@admin.register(AttendanceSession)
class AttendanceSessionAdmin(admin.ModelAdmin):
    list_display = ('course', 'teacher', 'code', 'status', 'started_at', 'expires_at', 'marked_count')
    list_filter = ('status',)
    search_fields = ('code', 'course__name', 'teacher__username')


@admin.register(AttendanceRecord)
class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ('student', 'course', 'session', 'status', 'marked_at')
    list_filter = ('status',)
    search_fields = ('student__username', 'course__name')
