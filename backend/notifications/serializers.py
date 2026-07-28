from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    time = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ['id', 'type', 'title', 'subtitle', 'is_read', 'is_important', 'created_at', 'time']

    def get_time(self, obj):
        return obj.created_at.strftime('%I:%M %p')
