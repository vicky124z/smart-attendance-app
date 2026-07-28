import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


class UserRole(models.TextChoices):
    ADMIN = 'admin', 'Administrator'
    TEACHER = 'teacher', 'Teacher'
    STUDENT = 'student', 'Student'


class User(AbstractUser):
    """
    Custom user model shared by Administrators, Teachers and Students.
    `username` is kept (inherited) but we primarily authenticate via email.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.STUDENT)
    phone = models.CharField(max_length=20, blank=True, default='')
    avatar_url = models.URLField(blank=True, default='')

    department = models.ForeignKey(
        'academics.Department', null=True, blank=True,
        on_delete=models.SET_NULL, related_name='members',
    )

    # Student specific
    student_code = models.CharField(max_length=30, blank=True, default='', unique=False)
    semester = models.CharField(max_length=30, blank=True, default='')

    # Teacher specific
    employee_code = models.CharField(max_length=30, blank=True, default='')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.get_full_name() or self.username} ({self.role})'

    @property
    def display_id(self):
        """Student ID / Employee code used as the human friendly identifier."""
        if self.role == UserRole.STUDENT:
            return self.student_code
        if self.role == UserRole.TEACHER:
            return self.employee_code
        return str(self.id)[:8].upper()
