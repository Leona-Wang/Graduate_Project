import csv
from backend.models import Location
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = 'Create Location'

    def handle(self, *args, **options):

        locations = []

        with open('location.csv', newline='', encoding='utf-8') as file:

            reader = csv.DictReader(file)

            for row in reader:
                eventType = Location(locationName=row['location'])
                locations.append(eventType)

        Location.objects.bulk_create(locations)

        print("建立 locations 完成")
