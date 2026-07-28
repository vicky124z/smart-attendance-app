"""
URL configuration for the Smart Attendance backend.
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path


def api_root(request):
    return JsonResponse({
        'name': 'Smart Attendance API',
        'version': '1.0',
        'endpoints': {
            'auth': {
                'register': '/api/accounts/auth/register/',
                'login': '/api/accounts/auth/login/',
                'refresh': '/api/accounts/auth/refresh/',
                'change_password': '/api/accounts/auth/change-password/',
                'me': '/api/accounts/me/',
            },
            'academics': '/api/academics/',
            'attendance': '/api/attendance/',
            'notifications': '/api/notifications/',
        },
    })


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', api_root, name='api_root'),
    path('api/accounts/', include('accounts.urls')),
    path('api/academics/', include('academics.urls')),
    path('api/attendance/', include('attendance.urls')),
    path('api/notifications/', include('notifications.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
