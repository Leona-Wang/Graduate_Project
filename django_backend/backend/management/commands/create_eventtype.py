import csv
from backend.models import EventType
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = 'Create EventType'

    def handle(self, *args, **options):

        eventTypes = []

        with open('eventType.csv', newline='', encoding='utf-8') as file:

            reader = csv.DictReader(file)

            for row in reader:
                eventType = EventType(typeName=row['eventType'])
                eventTypes.append(eventType)

        EventType.objects.bulk_create(eventTypes)

        print("建立 eventType 完成")
