from rest_framework import serializers

from .models import AttendanceRecord, AttendanceSession


class AttendanceSessionSerializer(serializers.ModelSerializer):
    course_name = serializers.CharField(source='course.name', read_only=True)
    course_code = serializers.CharField(source='course.code', read_only=True)
    teacher_name = serializers.SerializerMethodField()
    marked_count = serializers.IntegerField(read_only=True)
    total_enrolled = serializers.IntegerField(read_only=True)
    qr_payload = serializers.CharField(read_only=True)
    is_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = AttendanceSession
        fields = [
            'id', 'course', 'course_name', 'course_code', 'teacher', 'teacher_name',
            'room', 'session_type', 'duration_minutes', 'gps_verification', 'face_recognition',
            'code', 'qr_payload', 'status', 'is_active', 'started_at', 'expires_at', 'closed_at',
            'marked_count', 'total_enrolled',
        ]
        read_only_fields = ['id', 'teacher', 'code', 'status', 'started_at', 'expires_at', 'closed_at']

    def get_teacher_name(self, obj):
        return obj.teacher.get_full_name() or obj.teacher.username


class CreateSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = AttendanceSession
        fields = [
            'course', 'room', 'session_type', 'duration_minutes',
            'gps_verification', 'face_recognition',
        ]

    def create(self, validated_data):
        from datetime import timedelta

        from django.utils import timezone

        request = self.context['request']
        duration = validated_data.get('duration_minutes', 60)
        session = AttendanceSession.objects.create(
            teacher=request.user,
            expires_at=timezone.now() + timedelta(minutes=duration),
            **validated_data,
        )
        return session


class MarkAttendanceSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=64)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)

    def validate_code(self, value):
        # Accept either the raw session code, or the full "uuid:code" QR payload.
        raw = value.strip()
        if ':' in raw:
            raw = raw.split(':')[-1]
        try:
            session = AttendanceSession.objects.get(code=raw)
        except AttendanceSession.DoesNotExist:
            raise serializers.ValidationError('Invalid or unknown session code.')
        if not session.is_active:
            raise serializers.ValidationError('This session has expired or been closed.')
        return session

    def create(self, validated_data):
        session = validated_data['code']
        student = self.context['request'].user

        if not session.course.enrollments.filter(student=student).exists():
            raise serializers.ValidationError('You are not enrolled in this course.')

        record, created = AttendanceRecord.objects.get_or_create(
            session=session,
            student=student,
            defaults={
                'course': session.course,
                'status': AttendanceRecord.STATUS_PRESENT,
                'latitude': validated_data.get('latitude'),
                'longitude': validated_data.get('longitude'),
            },
        )
        if not created:
            raise serializers.ValidationError('Attendance already marked for this session.')
        return record


class AttendanceRecordSerializer(serializers.ModelSerializer):
    course_name = serializers.CharField(source='course.name', read_only=True)
    course_code = serializers.CharField(source='course.code', read_only=True)
    student_name = serializers.SerializerMethodField()

    class Meta:
        model = AttendanceRecord
        fields = [
            'id', 'session', 'student', 'student_name', 'course', 'course_name', 'course_code',
            'status', 'marked_at', 'latitude', 'longitude',
        ]

    def get_student_name(self, obj):
        return obj.student.get_full_name() or obj.student.username
