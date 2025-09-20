# api/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from .models import Child, GameSession, RawData
from .serializers import ChildSerializer, GameSessionSerializer, RawDataSerializer

class ChildViewSet(viewsets.ModelViewSet):
    queryset = Child.objects.all()
    serializer_class = ChildSerializer
    permission_classes = [IsAuthenticated]

class GameSessionViewSet(viewsets.ModelViewSet):
    queryset = GameSession.objects.all()
    serializer_class = GameSessionSerializer
    permission_classes = [IsAuthenticated]

@api_view(['POST'])
def submit_drawing_data(request):
    """
    Receives drawing data for a specific game session and saves it.
    """
    session_id = request.data.get('session_id')
    drawing_data = request.data.get('drawing_data')

    if not session_id or not drawing_data:
        return Response(
            {"error": "session_id and drawing_data are required."},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        game_session = GameSession.objects.get(pk=session_id)
    except GameSession.DoesNotExist:
        return Response(
            {"error": "GameSession not found."},
            status=status.HTTP_404_NOT_FOUND
        )

    # Create or update the RawData for this session
    raw_data, created = RawData.objects.update_or_create(
        session=game_session,
        defaults={'data_json': drawing_data}
    )

    # Mark the session as completed
    game_session.completed = True
    game_session.save()

    return Response(
        {"success": f"Data for session {session_id} saved successfully."},
        status=status.HTTP_201_CREATED
    )

@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """
    User login endpoint
    """
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response(
            {"error": "Username and password are required."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user = authenticate(username=username, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
        })
    else:
        return Response(
            {"error": "Invalid credentials."},
            status=status.HTTP_401_UNAUTHORIZED
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """
    User registration endpoint
    """
    username = request.data.get('username')
    email = request.data.get('email')
    password = request.data.get('password')
    
    if not username or not email or not password:
        return Response(
            {"error": "Username, email, and password are required."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if User.objects.filter(username=username).exists():
        return Response(
            {"error": "Username already exists."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if User.objects.filter(email=email).exists():
        return Response(
            {"error": "Email already exists."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password
    )
    
    token = Token.objects.create(user=user)
    return Response({
        "token": token.key,
        "user_id": user.id,
        "username": user.username,
        "email": user.email,
    }, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    User logout endpoint
    """
    try:
        request.user.auth_token.delete()
        return Response({"message": "Successfully logged out."})
    except:
        return Response(
            {"error": "Error logging out."},
            status=status.HTTP_400_BAD_REQUEST
        )