import uuid

from django.conf import settings
from django.db import models


class NotificationType(models.TextChoices):
    ATTENDANCE = 'attendance', 'Attendance'
    SESSION = 'session', 'Session'
    WARNING = 'warning', 'Warning'
    ANNOUNCEMENT = 'announcement', 'Announcement'


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications',
    )
    type = models.CharField(max_length=20, choices=NotificationType.choices, default=NotificationType.ANNOUNCEMENT)
    title = models.CharField(max_length=150)
    subtitle = models.CharField(max_length=255, blank=True, default='')
    is_read = models.BooleanField(default=False)
    is_important = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} -> {self.recipient}'
