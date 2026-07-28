import secrets
import uuid
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


def generate_session_code():
    return secrets.token_hex(8).upper()


class AttendanceSession(models.Model):
    """A live attendance-taking session created by a Teacher, identified by a QR code."""

    STATUS_ACTIVE = 'active'
    STATUS_CLOSED = 'closed'
    STATUS_EXPIRED = 'expired'
    STATUS_CHOICES = [
        (STATUS_ACTIVE, 'Active'),
        (STATUS_CLOSED, 'Closed'),
        (STATUS_EXPIRED, 'Expired'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    course = models.ForeignKey('academics.Course', on_delete=models.CASCADE, related_name='sessions')
    teacher = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sessions_created',
        limit_choices_to={'role': 'teacher'},
    )
    room = models.CharField(max_length=50, blank=True, default='')
    session_type = models.CharField(max_length=30, default='Lecture')
    duration_minutes = models.PositiveIntegerField(default=60)
    gps_verification = models.BooleanField(default=False)
    face_recognition = models.BooleanField(default=False)

    code = models.CharField(max_length=32, unique=True, default=generate_session_code)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_ACTIVE)

    started_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-started_at']

    def save(self, *args, **kwargs):
        if not self.expires_at:
            ttl = getattr(settings, 'SESSION_CODE_TTL_SECONDS', 1800)
            self.expires_at = timezone.now() + timedelta(seconds=ttl)
        super().save(*args, **kwargs)

    def __str__(self):
        return f'{self.course.code} session {self.code}'

    @property
    def qr_payload(self):
        return f'{self.id}:{self.code}'

    @property
    def is_expired(self):
        return timezone.now() >= self.expires_at

    @property
    def is_active(self):
        return self.status == self.STATUS_ACTIVE and not self.is_expired

    def close(self):
        self.status = self.STATUS_CLOSED
        self.closed_at = timezone.now()
        self.save(update_fields=['status', 'closed_at'])

    @property
    def marked_count(self):
        return self.records.filter(status=AttendanceRecord.STATUS_PRESENT).count()

    @property
    def total_enrolled(self):
        return self.course.enrollments.count()


class AttendanceRecord(models.Model):
    STATUS_PRESENT = 'present'
    STATUS_ABSENT = 'absent'
    STATUS_CHOICES = [
        (STATUS_PRESENT, 'Present'),
        (STATUS_ABSENT, 'Absent'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(AttendanceSession, on_delete=models.CASCADE, related_name='records')
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='attendance_records',
        limit_choices_to={'role': 'student'},
    )
    course = models.ForeignKey('academics.Course', on_delete=models.CASCADE, related_name='attendance_records')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_PRESENT)
    marked_at = models.DateTimeField(auto_now_add=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ['-marked_at']
        unique_together = ('session', 'student')

    def __str__(self):
        return f'{self.student} - {self.course.code} - {self.status}'
