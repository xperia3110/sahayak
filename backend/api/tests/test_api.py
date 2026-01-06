from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from .models import ParentProfile

class AuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.register_url = '/api/auth/register/'
        self.login_url = '/api/auth/login/'
        self.user_data = {
            'username': 'testparent',
            'email': 'parent@example.com',
            'password': 'password123',
            'first_name': 'Test',
            'last_name': 'Parent',
            'middle_name': 'M',
            'phone_number': '1234567890'
        }

    def test_parent_registration(self):
        response = self.client.post(self.register_url, self.user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('token', response.data)
        self.assertIn('user', response.data)
        
        # Verify User creation
        user = User.objects.get(username='testparent')
        self.assertEqual(user.email, 'parent@example.com')
        self.assertEqual(user.first_name, 'Test')
        
        # Verify Profile creation
        profile = ParentProfile.objects.get(user=user)
        self.assertEqual(profile.middle_name, 'M')
        self.assertEqual(profile.phone_number, '1234567890')

    def test_login(self):
        # Register first
        self.client.post(self.register_url, self.user_data, format='json')
        
        # Login
        login_data = {
            'username': 'testparent',
            'password': 'password123'
        }
        response = self.client.post(self.login_url, login_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['first_name'], 'Test')
        self.assertEqual(response.data['user']['phone_number'], '1234567890')
