# api/models.py

from django.db import models
from django.contrib.auth.models import User

class Child(models.Model):
    parent = models.ForeignKey(User, on_delete=models.CASCADE)
    nickname = models.CharField(max_length=100)
    age_in_months = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.nickname} (Parent: {self.parent.username})"

class GameSession(models.Model):
    child = models.ForeignKey(Child, on_delete=models.CASCADE)
    game_type = models.CharField(max_length=50) # e.g., 'EchoExplorers', 'StarTracer'
    session_start_time = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)

    def __str__(self):
        return f"Session {self.id} for {self.child.nickname} ({self.game_type})"

class RawData(models.Model):
    session = models.OneToOneField(GameSession, on_delete=models.CASCADE, primary_key=True)
    data_json = models.JSONField() # Stores the detailed gameplay data
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Raw Data for Session {self.session.id}"

class AnalysisResult(models.Model):
    session = models.OneToOneField(GameSession, on_delete=models.CASCADE, primary_key=True)
    dyslexia_risk = models.FloatField(null=True, blank=True)
    dysgraphia_risk = models.FloatField(null=True, blank=True)
    dyscalculia_risk = models.FloatField(null=True, blank=True)
    report_summary = models.TextField(blank=True)
    generated_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Analysis for Session {self.session.id}"