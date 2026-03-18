# api/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ChildViewSet, GameSessionViewSet, submit_drawing_data, login, register, logout, analyze_stroke, analyze_dyslexia, analyze_dyscalculia, get_child_report

router = DefaultRouter()
router.register(r'children', ChildViewSet, basename='child')
router.register(r'sessions', GameSessionViewSet, basename='gamesession')

urlpatterns = [
    path('', include(router.urls)),
    path('auth/login/', login, name='login'),
    path('auth/register/', register, name='register'),
    path('auth/logout/', logout, name='logout'),
    path('games/submit-drawing/', submit_drawing_data, name='submit_drawing'),
    path('games/analyze-stroke/', analyze_stroke, name='analyze_stroke'),
    path('games/analyze-dyslexia/', analyze_dyslexia, name='analyze_dyslexia'),
    path('games/analyze-dyscalculia/', analyze_dyscalculia, name='analyze_dyscalculia'),
    path('children/<int:child_id>/report/', get_child_report, name='get_child_report'),
]