from django.core.management.base import BaseCommand
import json


class Command(BaseCommand):
    help = 'Edit Initial Data'

    def handle(self, *args, **options):
        with open('initial_data.json', encoding='utf-8') as file:
            data = json.load(file)

        org_items = [obj for obj in data if obj['model'] == 'backend.organization']

        for i, obj in enumerate(org_items, start=1):
            obj['pk'] = i

        with open('initial_data_fixed.json', 'w', encoding='utf-8') as file:
            json.dump(data, file, ensure_ascii=False, indent=2)
