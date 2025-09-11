# api/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Child, GameSession, RawData
from .serializers import ChildSerializer, GameSessionSerializer, RawDataSerializer

class ChildViewSet(viewsets.ModelViewSet):
    queryset = Child.objects.all()
    serializer_class = ChildSerializer

class GameSessionViewSet(viewsets.ModelViewSet):
    queryset = GameSession.objects.all()
    serializer_class = GameSessionSerializer

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