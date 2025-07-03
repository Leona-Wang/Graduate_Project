"""使用方式
1. class 名稱： function 或 class 名稱+test(例如 class 叫 ABC -> ABCTest)
2. method 務必以 test 開頭(test case 基本上都是給 GPT 寫，只需要記得用 lower camel case 寫就好)
3.呼叫方式：
    -只測試單一 class ：python manage.py test tests.backend.viewsTest.class名(例如python manage.py test tests.backend.viewsTest.CaseTest)
    -測全部：python manage.py test tests.backend.viewsTest
"""

from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth.models import User
from backend.models import PersonalInfo, CharityInfo, Location, EventType, Organization


class CaseTest(TestCase):

    def setUp(self):
        self.integer = 1

    def testFileCanUse(self):
        testInt = self.integer
        self.assertEqual(testInt, 1)


class CreateUserTest(TestCase):

    def setUp(self):
        self.client = Client()
        self.url = reverse('createUser')

    def testCreatePersonalUserSuccess(self):
        data = {
            'personalEmail': 'test@example.com',
            'personalPassword': 'password123',
            'personalPasswordConfirm': 'password123'
        }
        response = self.client.post(f'{self.url}?type=personal', data)
        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(response.content, {'success': True})
        self.assertTrue(User.objects.filter(email='test@example.com').exists())

    def testCreateCharityUserSuccess(self):
        data = {
            'charityEmail': 'charity@example.com',
            'charityPassword': 'password123',
            'charityPasswordConfirm': 'password123'
        }
        response = self.client.post(f'{self.url}?type=charity', data)
        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(response.content, {'success': True})
        self.assertTrue(User.objects.filter(email='charity@example.com').exists())

    def testPasswordMismatchError(self):
        data = {
            'personalEmail': 'fail@example.com',
            'personalPassword': 'password123',
            'personalPasswordConfirm': 'differentPassword'
        }
        response = self.client.post(f'{self.url}?type=personal', data)
        self.assertEqual(response.status_code, 400)
        self.assertJSONEqual(response.content, {'success': False, 'message': '密碼輸入不同，請重新輸入'})

    def testInvalidAccountTypeError(self):
        data = {'someEmail': 'fail@example.com', 'somePassword': 'password123', 'somePasswordConfirm': 'password123'}
        response = self.client.post(f'{self.url}?type=unknown', data)
        self.assertEqual(response.status_code, 400)
        self.assertJSONEqual(response.content, {'success': False, 'message': '無此帳號分類'})

    def testMissingTypeQueryParamError(self):
        data = {
            'personalEmail': 'fail@example.com',
            'personalPassword': 'password123',
            'personalPasswordConfirm': 'password123'
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, 400)
        self.assertJSONEqual(response.content, {'success': False, 'message': '無此帳號分類'})

    def testExceptionHandling(self):
        User.objects.create_user(
            email='duplicate@example.com', username='duplicate@example.com', password='password123'
        )
        data = {
            'personalEmail': 'duplicate@example.com',
            'personalPassword': 'password123',
            'personalPasswordConfirm': 'password123'
        }
        response = self.client.post(f'{self.url}?type=personal', data)
        self.assertEqual(response.status_code, 400)

        jsonData = response.json()
        self.assertFalse(jsonData['success'])
        self.assertIn('message', jsonData)


class CreatePersonalInfoTest(TestCase):

    def setUp(self):
        self.client = Client()
        self.createPersonalInfoUrl = reverse('createPersonalInfo') # 你的 urls.py 裡要有這個 name
        self.testEmail = 'test@example.com'
        self.testNickname = 'TestNick'
        self.testLocationName = 'Taipei'
        self.testEventTypeName = 'Music'

        # Django 內建 User 需要 username
        self.user = User.objects.create_user(username='testuser', email=self.testEmail, password='testpass')

        self.location = Location.objects.create(locationName=self.testLocationName)
        self.eventType = EventType.objects.create(typeName=self.testEventTypeName)

    def testCreatePersonalInfoSuccess(self):
        requestData = {
            'email': self.testEmail,
            'nickname': self.testNickname,
            'location': self.testLocationName,
            'eventType': [self.testEventTypeName]
        }

        response = self.client.post(self.createPersonalInfoUrl, data=requestData, content_type='application/json')

        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(str(response.content, encoding='utf8'), {'success': True})

        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, self.testNickname)

        personalInfo = PersonalInfo.objects.get(user=self.user)
        self.assertEqual(personalInfo.location, self.location)
        self.assertIn(self.eventType, personalInfo.eventType.all())

    def testCreatePersonalInfoInvalidUser(self):
        requestData = {
            'email': 'notfound@example.com',
            'nickname': 'NoUser',
            'location': self.testLocationName,
            'eventType': [self.testEventTypeName]
        }

        response = self.client.post(self.createPersonalInfoUrl, data=requestData, content_type='application/json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('success', response.json())
        self.assertFalse(response.json()['success'])


class CreateCharityInfoTest(TestCase):

    def setUp(self):
        self.client = Client()

        self.testEmail = "test@example.com"
        self.user = User.objects.create(email=self.testEmail)

        self.testOrganization = Organization.objects.create(code=1, name="Test Organization")

        self.testEventType = EventType.objects.create(typeName="教育類")

        self.url = reverse('createCharityInfo')

    def testCreateCharityWithExistingOrganization(self):
        requestData = {
            "email": self.testEmail,
            "groupName": "新名字",
            "groupType": "教育類",
            "groupAddress": "台北市中正區",
            "groupPhone": "0912345678",
            "groupId": "1" # 這裡改成可轉int的字串
        }

        response = self.client.post(self.url, data=requestData)
        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(response.content, {"success": True})

        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, "新名字")

        charity = CharityInfo.objects.get(user=self.user)
        self.assertEqual(charity.organization, self.testOrganization)
        self.assertIsNone(charity.address)
        self.assertIsNone(charity.phone)

    def testCreateCharityWithNewOrganization(self):
        requestData = {
            "email": self.testEmail,
            "groupName": "另一個名字",
            "groupType": "教育類",
            "groupAddress": "高雄市前鎮區",
            "groupPhone": "0987654321",
            "groupId": "99999" # 新組織用不存在的整數id表示
        }

        response = self.client.post(self.url, data=requestData)
        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(response.content, {"success": True})

        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, "另一個名字")

        charity = CharityInfo.objects.get(user=self.user)
        self.assertIsNone(charity.organization) # 新組織組織不存在
        self.assertEqual(charity.address, "高雄市前鎮區")
        self.assertEqual(charity.phone, "0987654321")
        self.assertEqual(charity.type, self.testEventType)

    def testCreateCharityWithInvalidUser(self):
        requestData = {
            "email": "notfound@example.com",
            "groupName": "不存在的使用者",
            "groupType": "教育類",
            "groupAddress": "台南市",
            "groupPhone": "0911111111",
            "groupId": "1" # 這裡改成1
        }

        response = self.client.post(self.url, data=requestData)
        self.assertEqual(response.status_code, 400)
        self.assertIn("success", response.json())
        self.assertFalse(response.json()["success"])
