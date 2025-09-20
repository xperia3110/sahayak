# api/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ChildViewSet, GameSessionViewSet, submit_drawing_data, login, register, logout

router = DefaultRouter()
router.register(r'children', ChildViewSet)
router.register(r'sessions', GameSessionViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/login/', login, name='login'),
    path('auth/register/', register, name='register'),
    path('auth/logout/', logout, name='logout'),
    path('games/submit-drawing/', submit_drawing_data, name='submit_drawing'),
]