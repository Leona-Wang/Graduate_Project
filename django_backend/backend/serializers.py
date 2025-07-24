from rest_framework import serializers
from .models import CharityEvent


class CharityEventSerializer(serializers.ModelSerializer):

    class Meta:
        model = CharityEvent
        fields = '__all__'
