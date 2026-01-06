# api/serializers.py

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Child, GameSession, RawData, ParentProfile

class ParentRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)
    email = serializers.EmailField(required=True)
    middle_name = serializers.CharField(required=False, allow_blank=True)
    phone_number = serializers.CharField(required=True)

    class Meta:
        model = User
        fields = ('username', 'password', 'email', 'first_name', 'last_name', 'middle_name', 'phone_number')

    def create(self, validated_data):
        # Extract profile data
        middle_name = validated_data.pop('middle_name', '')
        phone_number = validated_data.pop('phone_number', '')
        
        # Create User
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name']
        )
        
        # Create ParentProfile
        ParentProfile.objects.create(
            user=user,
            middle_name=middle_name,
            phone_number=phone_number
        )
        
        return user

class UserSerializer(serializers.ModelSerializer):
    middle_name = serializers.CharField(source='parent_profile.middle_name', read_only=True)
    phone_number = serializers.CharField(source='parent_profile.phone_number', read_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'middle_name', 'phone_number')

class ChildSerializer(serializers.ModelSerializer):
    class Meta:
        model = Child
        fields = '__all__'
        read_only_fields = ('parent',)

class GameSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = GameSession
        fields = '__all__'

class RawDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = RawData
        fields = '__all__'