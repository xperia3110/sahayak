# Register your models here.
# api/admin.py

from django.contrib import admin
from .models import Child, GameSession, RawData, AnalysisResult

admin.site.register(Child)
admin.site.register(GameSession)
admin.site.register(RawData)
admin.site.register(AnalysisResult)
