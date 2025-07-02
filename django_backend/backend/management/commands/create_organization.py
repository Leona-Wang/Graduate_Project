import csv
from backend.models import Organization, ServiceGender, EventType, Location
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = 'Create Organization'

    def handle(self, *args, **options):
        organizations = []

        orgRowList = []

        with open('orgDetailList.csv', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)

            for row in reader:
                if not any(row.values()):
                    break

                code = row['code']
                name = row['name']
                CEO = row['CEO']
                contact = row['contact']
                phone = row['phone']
                fax = row['fax']
                website = row['website']
                email = row['email']
                address = row['address']
                founder = row['founder']
                founded = row['founded']
                authority = row['authority']
                mission = row['mission']
                focus = row['focus']
                minAge = row['minAge']
                maxAge = row['maxAge']
                service = row['service']

                type = EventType.objects.filter(typeName=row['type']).first()
                gender = ServiceGender.objects.filter(gender=row['gender']).first()

                org = Organization(
                    code=code,
                    name=name,
                    CEO=CEO,
                    contact=contact,
                    phone=phone,
                    fax=fax,
                    website=website,
                    email=email,
                    address=address,
                    founder=founder,
                    founded=founded,
                    authority=authority,
                    mission=mission,
                    focus=focus,
                    minAge=minAge,
                    maxAge=maxAge,
                    service=service,
                    type=type,
                    gender=gender
                )
                organizations.append(org)
                orgRowList.append(row)

                print(f"{code} fin")

        Organization.objects.bulk_create(organizations)
        print("建立 organizations 完成")

        with open('orgDetailList.csv', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)

            for row in reader:
                if not any(row.values()):
                    break

                code = row['code']
                organization = Organization.objects.filter(code=code).first()

                if row['area']:
                    locationNames = [n.strip() for n in row['area'].split(',')]
                    for name in locationNames:
                        if name:
                            loc, _ = Location.objects.get_or_create(locationName=name)
                            organization.area.add(loc)
                    print(f"{code} fin")
                else:
                    print(f"{code} no location")

            print(f"建立 organizations location 完成")
