from django.core.management.base import BaseCommand
from django.utils import timezone
from backend.models import CharityEvent
from django.conf import settings

class Command(BaseCommand):
    help = "每日自動檢查 CharityEvent 狀態並更新"

    def handle(self, *args, **options):
        now = timezone.now()
        events = CharityEvent.objects.exclude(status=settings.CHARITY_EVENT_STATUS_DELETED)

        updated_count = 0
        for event in events:
            old_status = event.status
            # 狀態判斷
            if event.startTime and (not event.endTime):
                # 只有開始時間，沒有結束時間
                if now < event.startTime:
                    event.status = settings.CHARITY_EVENT_STATUS_UPCOMING
                else:
                    event.status = settings.CHARITY_EVENT_STATUS_ONGOING
            elif event.startTime and event.endTime:
                if now < event.startTime:
                    event.status = settings.CHARITY_EVENT_STATUS_UPCOMING
                elif event.startTime <= now <= event.endTime:
                    event.status = settings.CHARITY_EVENT_STATUS_ONGOING
                elif now > event.endTime:
                    event.status = settings.CHARITY_EVENT_STATUS_FINISHED
            else:
                event.status = settings.CHARITY_EVENT_STATUS_UNKNOWN

            if event.status != old_status:
                event.save()
                updated_count += 1

        self.stdout.write(self.style.SUCCESS(f'已更新 {updated_count} 筆 CharityEvent 狀態'))