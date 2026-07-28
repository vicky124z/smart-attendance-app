from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register('sessions', views.AttendanceSessionViewSet, basename='session')
router.register('records', views.AttendanceRecordViewSet, basename='record')

urlpatterns = [
    path('mark/', views.MarkAttendanceView.as_view(), name='mark_attendance'),
    path('my-stats/', views.MyAttendanceStatsView.as_view(), name='my_attendance_stats'),
    path('dashboard/student/', views.StudentDashboardView.as_view(), name='student_dashboard'),
    path('dashboard/teacher/', views.TeacherDashboardView.as_view(), name='teacher_dashboard'),
    path('dashboard/admin/', views.AdminDashboardView.as_view(), name='admin_dashboard'),
    path('analytics/admin/', views.AdminAnalyticsView.as_view(), name='admin_analytics'),
] + router.urls
