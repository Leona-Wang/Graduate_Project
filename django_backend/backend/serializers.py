from rest_framework import serializers
from .models import CharityEvent, EventParticipant
from django.conf import settings


class CharityEventSerializer(serializers.ModelSerializer):
    saveAmount = serializers.SerializerMethodField()
    joinAmount = serializers.SerializerMethodField()

    class Meta:
        model = CharityEvent
        fields = '__all__'

    def getSaveAmount(self, obj):
        return EventParticipant.objects.filter(charityEvent=obj, joinType=settings.CHARITY_EVENT_SAVE).count()

    def getJoinAmount(self, obj):
        return EventParticipant.objects.filter(charityEvent=obj, joinType=settings.CHARITY_EVENT_JOIN).count()
