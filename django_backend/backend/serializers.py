from rest_framework import serializers
from .models import CharityEvent, EventParticipant
from django.conf import settings


class CharityEventSerializer(serializers.ModelSerializer):
    saveAmount = serializers.SerializerMethodField(method_name='getSaveAmount')
    joinAmount = serializers.SerializerMethodField(method_name='getJoinAmount')
    mainOrganizer = serializers.CharField(source='mainOrganizer.user.first_name', read_only=True)
    eventType = serializers.CharField(source='eventType.typeName', read_only=True)
    location = serializers.CharField(source='location.locationName', read_only=True)
    statusDisplay = serializers.SerializerMethodField()

    class Meta:
        model = CharityEvent
        fields = '__all__'

    def getSaveAmount(self, obj):
        return EventParticipant.objects.filter(charityEvent=obj, joinType=settings.CHARITY_EVENT_SAVE).count()

    def getJoinAmount(self, obj):
        return EventParticipant.objects.filter(charityEvent=obj, joinType=settings.CHARITY_EVENT_JOIN).count()

    # 新增statusDisplay(中文狀態)欄位
    def get_statusDisplay(self, obj):
        status = obj.status or 'unknown'
        return settings.CHARITY_EVENT_STATUS_DISPLAY.get(status, '未知')
