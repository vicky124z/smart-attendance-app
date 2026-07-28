from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, permissions, viewsets

from accounts.permissions import IsAdmin
from .models import ClassSchedule, Course, Department, Enrollment
from .serializers import (
    ClassScheduleSerializer,
    CourseSerializer,
    DepartmentSerializer,
    EnrollmentSerializer,
)


class IsAdminOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated
        return request.user and request.user.is_authenticated and request.user.role == 'admin'


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    permission_classes = [IsAdminOrReadOnly]
    search_fields = ['name', 'code']
    filter_backends = [filters.SearchFilter]


class CourseViewSet(viewsets.ModelViewSet):
    queryset = Course.objects.select_related('department', 'teacher').prefetch_related('schedules')
    serializer_class = CourseSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['department', 'teacher', 'semester']
    search_fields = ['name', 'code']

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if user.role == 'teacher':
            return qs.filter(teacher=user)
        if user.role == 'student':
            return qs.filter(enrollments__student=user)
        return qs


class ClassScheduleViewSet(viewsets.ModelViewSet):
    queryset = ClassSchedule.objects.select_related('course')
    serializer_class = ClassScheduleSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['course', 'weekday']


class EnrollmentViewSet(viewsets.ModelViewSet):
    queryset = Enrollment.objects.select_related('student', 'course')
    serializer_class = EnrollmentSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['student', 'course']
