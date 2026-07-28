from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True, default='')
    attendance_percentage = serializers.SerializerMethodField()
    display_id = serializers.CharField(read_only=True)
    name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'name', 'first_name', 'last_name', 'username', 'email', 'phone', 'role',
            'department', 'department_name', 'semester', 'student_code', 'employee_code',
            'avatar_url', 'display_id', 'attendance_percentage', 'date_joined',
        ]
        read_only_fields = ['id', 'role', 'date_joined']

    def get_name(self, obj):
        full = obj.get_full_name()
        return full or obj.username

    def get_attendance_percentage(self, obj):
        if obj.role != 'student':
            return None
        from attendance.models import AttendanceRecord
        total = AttendanceRecord.objects.filter(student=obj).count()
        if total == 0:
            return 0.0
        present = AttendanceRecord.objects.filter(student=obj, status='present').count()
        return round((present / total) * 100, 1)


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    role = serializers.ChoiceField(choices=['admin', 'teacher', 'student'])
    name = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'name', 'email', 'password', 'role', 'phone', 'department',
            'semester', 'student_code', 'employee_code',
        ]

    def create(self, validated_data):
        name = validated_data.pop('name', '')
        password = validated_data.pop('password')
        first, _, last = name.partition(' ')

        username_base = validated_data['email'].split('@')[0]
        username = username_base
        suffix = 1
        while User.objects.filter(username=username).exists():
            username = f'{username_base}{suffix}'
            suffix += 1

        user = User(
            username=username,
            first_name=first,
            last_name=last,
            **validated_data,
        )
        user.set_password(password)
        user.save()
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Allows logging in with email + password (and optionally validates the
    role selected on the mobile role-selection screen matches the account).
    """
    username_field = User.USERNAME_FIELD

    def validate(self, attrs):
        data = super().validate(attrs)
        data['user'] = UserSerializer(self.user).data
        return data

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        token['email'] = user.email
        return token


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
