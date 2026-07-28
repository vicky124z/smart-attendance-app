from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register('departments', views.DepartmentViewSet, basename='department')
router.register('courses', views.CourseViewSet, basename='course')
router.register('schedules', views.ClassScheduleViewSet, basename='schedule')
router.register('enrollments', views.EnrollmentViewSet, basename='enrollment')

urlpatterns = router.urls
