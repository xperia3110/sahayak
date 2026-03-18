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
        'session_id': int,
        'results': [...]
    }
    """
    session_id = request.data.get('session_id')
    results = request.data.get('results', [])
    
    if not session_id or not results:
        return Response({'error': 'Session ID and results are required'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        game_session = GameSession.objects.get(pk=session_id)
    except GameSession.DoesNotExist:
        return Response({'error': 'GameSession not found.'}, status=status.HTTP_404_NOT_FOUND)
    
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
        dyslexia_risk_value = 0.1
        if phonological_score < 60 or ran_score < 50:
            risk_level = 'high'
            dyslexia_risk_value = 0.8
        elif phonological_score < 80 or ran_score < 70:
            risk_level = 'moderate'
            dyslexia_risk_value = 0.5
            
        # Save to AnalysisResult
        from .models import AnalysisResult
        obj, created = AnalysisResult.objects.get_or_create(session=game_session)
        obj.dyslexia_risk = dyslexia_risk_value
        obj.report_summary += f"\nDyslexia screening complete. Accuracy: {round(accuracy, 1)}%. Processing: {processing_speed}. Risk: {risk_level}."
        obj.save()
        
        # Mark session completed
        game_session.completed = True
        game_session.save()
        
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
@permission_classes([IsAuthenticated])
def analyze_dyscalculia(request):
    """
    Analyze number sense and comparison for Dyscalculia screening.
    Expects JSON: {
        'session_id': int,
        'results': [...]
    }
    """
    session_id = request.data.get('session_id')
    results = request.data.get('results', [])
    
    if not session_id or not results:
        return Response({'error': 'Session ID and results are required'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        game_session = GameSession.objects.get(pk=session_id)
    except GameSession.DoesNotExist:
        return Response({'error': 'GameSession not found.'}, status=status.HTTP_404_NOT_FOUND)
        
    try:
        total_games = len(results)
        correct_count = sum(1 for r in results if r.get('is_correct'))
        accuracy = (correct_count / total_games) * 100 if total_games > 0 else 0
        
        # Analyze by game mode
        subitizing_results = [r for r in results if r.get('game_mode') == 'subitizing']
        comparison_results = [r for r in results if r.get('game_mode') == 'comparison']
        
        # Subitizing Analysis
        subitizing_score = 0
        if subitizing_results:
            sub_correct = sum(1 for r in subitizing_results if r.get('is_correct'))
            sub_total = len(subitizing_results)
            subitizing_score = (sub_correct / sub_total) * 100
        
        # Comparison Analysis (Distance Effect)
        comparison_score = 0
        distance_effect_detected = False
        if comparison_results:
            comp_correct = sum(1 for r in comparison_results if r.get('is_correct'))
            comp_total = len(comparison_results)
            comparison_score = (comp_correct / comp_total) * 100
            
            # Simple distance effect check: are they slower on close numbers (low ratio)?
            low_ratio = [r for r in comparison_results if r.get('ratio_type') == 'low']
            high_ratio = [r for r in comparison_results if r.get('ratio_type') == 'high']
            
            if low_ratio and high_ratio:
                avg_low = sum(r.get('reaction_time_ms', 0) for r in low_ratio) / len(low_ratio)
                avg_high = sum(r.get('reaction_time_ms', 0) for r in high_ratio) / len(high_ratio)
                
                # If low ratio (harder) takes significantly longer (> 500ms), strong distance effect
                distance_effect_detected = (avg_low - avg_high) > 500

        # Overall Risk Calculation
        risk_level = 'low'
        if accuracy < 60:
            risk_level = 'high'
        elif accuracy < 80:
            risk_level = 'moderate'
            
        if not distance_effect_detected:
            # Lack of distance effect is a strong indicator of dyscalculia
            if risk_level == 'moderate': 
                risk_level = 'high'
            elif risk_level == 'low':
                risk_level = 'moderate'
                
        dyscalculia_risk_value = 0.1
        if risk_level == 'high':
            dyscalculia_risk_value = 0.8
        elif risk_level == 'moderate':
            dyscalculia_risk_value = 0.5
            
        # Save to AnalysisResult
        from .models import AnalysisResult
        obj, created = AnalysisResult.objects.get_or_create(session=game_session)
        obj.dyscalculia_risk = dyscalculia_risk_value
        obj.report_summary += f"\nDyscalculia screening complete. Accuracy: {round(accuracy, 1)}%. Distance Effect expected: {distance_effect_detected}. Risk: {risk_level}."
        obj.save()
        
        # Mark session completed
        game_session.completed = True
        game_session.save()
                
        return Response({
            'accuracy': round(accuracy, 1),
            'correct_count': correct_count,
            'total_games': total_games,
            'subitizing_score': round(subitizing_score, 1),
            'comparison_score': round(comparison_score, 1),
            'distance_effect_detected': distance_effect_detected,
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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_child_report(request, child_id):
    """
    Get aggregated summary report for a specific child based on their latest GameSessions.
    """
    try:
        child = Child.objects.get(id=child_id, parent=request.user)
    except Child.DoesNotExist:
        return Response({'error': 'Child not found.'}, status=status.HTTP_404_NOT_FOUND)

    # Get all completed sessions for this child
    sessions = GameSession.objects.filter(child=child, completed=True).prefetch_related('analysisresult')
    
    if not sessions.exists():
        return Response({
            'message': 'No completed games yet.',
            'dyslexia_risk': 0.0,
            'dysgraphia_risk': 0.0,
            'dyscalculia_risk': 0.0,
            'summary': 'Play some games to get a report!'
        })
        
    dyslexia_risks = []
    dysgraphia_risks = []
    dyscalculia_risks = []
    
    for session in sessions:
        if hasattr(session, 'analysisresult'):
            ar = session.analysisresult
            if ar.dyslexia_risk is not None:
                dyslexia_risks.append(ar.dyslexia_risk)
            if ar.dysgraphia_risk is not None:
                dysgraphia_risks.append(ar.dysgraphia_risk)
            if ar.dyscalculia_risk is not None:
                dyscalculia_risks.append(ar.dyscalculia_risk)
                
    avg_dyslexia = sum(dyslexia_risks) / len(dyslexia_risks) if dyslexia_risks else 0.0
    avg_dysgraphia = sum(dysgraphia_risks) / len(dysgraphia_risks) if dysgraphia_risks else 0.0
    avg_dyscalculia = sum(dyscalculia_risks) / len(dyscalculia_risks) if dyscalculia_risks else 0.0
    
    # Overall diagnosis logic
    diagnosis = []
    if avg_dyslexia >= 0.6: diagnosis.append("Dyslexia (High Risk)")
    elif avg_dyslexia >= 0.4: diagnosis.append("Dyslexia (Moderate Risk)")
        
    if avg_dysgraphia >= 0.6: diagnosis.append("Dysgraphia (High Risk)")
    elif avg_dysgraphia >= 0.4: diagnosis.append("Dysgraphia (Moderate Risk)")
        
    if avg_dyscalculia >= 0.6: diagnosis.append("Dyscalculia (High Risk)")
    elif avg_dyscalculia >= 0.4: diagnosis.append("Dyscalculia (Moderate Risk)")
        
    if not diagnosis:
        summary = "Child is performing well within normal ranges. No immediate risks detected."
    else:
        summary = "Potential risks detected in: " + ", ".join(diagnosis) + ". We recommend consulting an educational specialist for a formal evaluation."
        
    return Response({
        'dyslexia_risk': round(avg_dyslexia, 2),
        'dysgraphia_risk': round(avg_dysgraphia, 2),
        'dyscalculia_risk': round(avg_dyscalculia, 2),
        'summary': summary
    })