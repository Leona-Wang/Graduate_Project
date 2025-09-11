from django.core.management.base import BaseCommand
from django.utils import timezone
from backend import Casino
from dateutil.relativedelta import relativedelta
from datetime import datetime, time


class Command(BaseCommand):
    help = "每個月定期開啟 casino 活動，期限一個月"

    def handle(self, *args, **options):

        startTime = timezone.make_aware(
            datetime.combine(timezone.now().date(), time.min), timezone.get_current_timezone()
        )
        endTime = startTime + relativedelta(months=1)

        casino = Casino.createCasino(startTime, endTime)
