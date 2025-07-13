from django.test import TestCase
from django.contrib.auth.models import User
from .models import Location, EventType, Organization, CharityEvent

from datetime import datetime, timedelta
from django.utils.timezone import make_aware


class LocationModelTest(TestCase):
    def test_create_location(self):
        location = Location.objects.create(locationName="台北市", latitude=25.0330, longitude=121.5654)
        self.assertEqual(location.locationName, "台北市")
        self.assertAlmostEqual(location.latitude, 25.0330)


class OrganizationModelTest(TestCase):
    def setUp(self):
        self.event_type = EventType.objects.create(typeName="教育")
        self.location = Location.objects.create(locationName="新北市")
        self.org = Organization.objects.create(code=101, name="慈善協會", type=self.event_type)
        self.org.area.add(self.location)

    def test_create_organization(self):
        self.assertEqual(self.org.name, "慈善協會")
        self.assertEqual(self.org.type.typeName, "教育")
        self.assertIn(self.location, self.org.area.all())


class CharityEventModelTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="pass")
        self.event_type = EventType.objects.create(typeName="募款")
        self.location = Location.objects.create(locationName="桃園")
        self.org = Organization.objects.create(code=202, name="社會服務基金會", type=self.event_type)
        self.now = make_aware(datetime.now())
        self.event = CharityEvent.objects.create(
            name="暑期募款活動",
            mainOrganizer=self.org,
            eventType=self.event_type,
            location=self.location,
            startTime=self.now,
            endTime=self.now + timedelta(days=1),
            createTime=self.now,
            status="正在舉辦"
        )
        self.event.participants.add(self.user)

    def test_charity_event_creation(self):
        self.assertEqual(self.event.name, "暑期募款活動")
        self.assertEqual(self.event.mainOrganizer.name, "社會服務基金會")
        self.assertIn(self.user, self.event.participants.all())
