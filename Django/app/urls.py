"""
URL configuration for app project.
"""
from django.contrib import admin
from django.urls import path
from django.http import JsonResponse

def health_check(request):
    """Health check endpoint"""
    return JsonResponse({'status': 'healthy'})

def home(request):
    """Home endpoint"""
    return JsonResponse({'message': 'Django app is running!'})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health', health_check, name='health'),
    path('', home, name='home'),
]

