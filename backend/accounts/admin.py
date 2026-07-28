from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'role', 'department', 'is_staff')
    list_filter = ('role', 'department', 'is_staff', 'is_active')
    search_fields = ('username', 'email', 'first_name', 'last_name', 'student_code', 'employee_code')
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Attendance App Info', {
            'fields': ('role', 'phone', 'department', 'student_code', 'semester', 'employee_code', 'avatar_url'),
        }),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Attendance App Info', {
            'fields': ('email', 'role', 'phone', 'department', 'student_code', 'semester', 'employee_code'),
        }),
    )
