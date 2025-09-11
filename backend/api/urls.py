# api/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ChildViewSet, GameSessionViewSet, submit_drawing_data

router = DefaultRouter()
router.register(r'children', ChildViewSet)
router.register(r'sessions', GameSessionViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('games/submit-drawing/', submit_drawing_data, name='submit_drawing'),
]