from backend import Casino
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import datetime, time
from backend.models import OfficialEvent
from django.conf import settings


class Command(BaseCommand):
    help = "時間到 casino 結算"

    def handle(self, *args, **options):

        now = timezone.make_aware(datetime.combine(timezone.now().date(), time.min), timezone.get_current_timezone())

        betEvent = OfficialEvent.objects.filter(type=settings.OFFICIAL_EVENT_TYPE_CASINO, endTime__lt=now).last()

        winner = Casino.getWinner(betEvent)
        result = Casino.saveWinner(winner, betEvent)
