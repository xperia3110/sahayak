# api/serializers.py

from rest_framework import serializers
from .models import Child, GameSession, RawData
from django.contrib.auth.models import User

class ChildSerializer(serializers.ModelSerializer):
    class Meta:
        model = Child
        fields = ['id', 'nickname', 'age_in_months', 'parent']

class GameSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = GameSession
        fields = ['id', 'child', 'game_type', 'session_start_time', 'completed']

class RawDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = RawData
        fields = ['session', 'data_json']