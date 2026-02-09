# api/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from .models import Child, GameSession, RawData
from .utils.kinematics import KinematicAnalyzer
from .serializers import ChildSerializer, GameSessionSerializer, RawDataSerializer, ParentRegistrationSerializer, UserSerializer

class ChildViewSet(viewsets.ModelViewSet):
    serializer_class = ChildSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Child.objects.filter(parent=self.request.user)

    def perform_create(self, serializer):
        serializer.save(parent=self.request.user)

class GameSessionViewSet(viewsets.ModelViewSet):
    serializer_class = GameSessionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return GameSession.objects.filter(child__parent=self.request.user)
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

    # Perform Analysis
    from .ml_utils import analyze_drawing
    from .models import AnalysisResult
    
    analysis_results = analyze_drawing(drawing_data)
    
    if "error" not in analysis_results:
        AnalysisResult.objects.update_or_create(
            session=game_session,
            defaults={
                'dyslexia_risk': analysis_results.get('dyslexia_risk'),
                'dysgraphia_risk': analysis_results.get('dysgraphia_risk'),
                'dyscalculia_risk': analysis_results.get('dyscalculia_risk'),
                'report_summary': "Automated analysis based on drawing patterns."
            }
        )

    # Mark the session as completed
    game_session.completed = True
    game_session.save()

    return Response(
        {
            "success": f"Data for session {session_id} saved successfully.",
            "analysis": analysis_results
        },
        status=status.HTTP_201_CREATED
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_stroke(request):
    """
    Analyze a stroke trace for Dysgraphia screening.
    Expects JSON: { 
        'user_points': [{'x':, 'y':, 't':}, ...], 
        'target_points': [{'x':, 'y':}, ...] (Optional) 
    }
    """
    user_points = request.data.get('user_points')
    target_points = request.data.get('target_points')
    
    if not user_points:
        return Response({'error': 'No points provided'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        results = KinematicAnalyzer.analyze_stroke(user_points, target_points)
        return Response(results)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_dyslexia(request):
    """
    Analyze phonological awareness and RAN for Dyslexia screening.
    Expects JSON: {
        'results': [
            {
                'question_id': str,
                'prompt': str,
                'user_answer': str,
                'is_correct': bool,
                'reaction_time_ms': int
            }
        ]
    }
    """
    results = request.data.get('results', [])
    
    if not results:
        return Response({'error': 'No results provided'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Calculate metrics
        total_questions = len(results)
        correct_count = sum(1 for r in results if r.get('is_correct'))
        accuracy = (correct_count / total_questions) * 100 if total_questions > 0 else 0
        
        # Reaction time analysis (crucial for Dyslexia)
        reaction_times = [r.get('reaction_time_ms', 0) for r in results]
        avg_reaction_time = sum(reaction_times) / len(reaction_times) if reaction_times else 0
        
        # RAN score based on reaction time
        # Slower processing (<2s = good, 2-4s = normal, >4s = delayed)
        if avg_reaction_time < 2000:
            ran_score = 90
            processing_speed = 'fast'
        elif avg_reaction_time < 4000:
            ran_score = 70
            processing_speed = 'normal'
        else:
            ran_score = 40
            processing_speed = 'delayed'
        
        # Overall phonological awareness score
        phonological_score = accuracy
        
        # Risk assessment
        risk_level = 'low'
        if phonological_score < 60 or ran_score < 50:
            risk_level = 'high'
        elif phonological_score < 80 or ran_score < 70:
            risk_level = 'moderate'
        
        return Response({
            'accuracy': round(accuracy, 1),
            'correct_count': correct_count,
            'total_questions': total_questions,
            'avg_reaction_time_ms': round(avg_reaction_time),
            'ran_score': ran_score,
            'processing_speed': processing_speed,
            'phonological_score': round(phonological_score, 1),
            'risk_level': risk_level,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
        user_serializer = UserSerializer(user)
        return Response({
            "token": token.key,
            "user": user_serializer.data,
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
    Parent registration endpoint
    """
    serializer = ParentRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)
        user_serializer = UserSerializer(user)
        return Response({
            "token": token.key,
            "user": user_serializer.data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_stroke(request):
    """
    Analyze a stroke trace for Dysgraphia screening.
    Expects JSON: { 
        'user_points': [{'x':, 'y':, 't':}, ...], 
        'target_points': [{'x':, 'y':}, ...] (Optional) 
    }
    """
    user_points = request.data.get('user_points')
    target_points = request.data.get('target_points')
    
    if not user_points:
        return Response({'error': 'No points provided'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        results = KinematicAnalyzer.analyze_stroke(user_points, target_points)
        return Response(results)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)