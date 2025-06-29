from django.test import TestCase

# Create your tests here.
from .models import User, PetType, Pet, PetList

class UserModelTest(TestCase):
    def setUp(self):
        # 新增一個 User
        self.user = User.objects.create(
            email="test@example.com",
            name="測試用戶",
            password="hashedpassword",
            identity="normal",
            group_type="groupA",
            group_id="G001",
            group_address="台北市",
            group_phone="0912345678"
        )

    def test_user_creation(self):
        user = User.objects.get(email="test@example.com")
        self.assertEqual(user.name, "測試用戶")
        self.assertEqual(user.group_id, "G001")

class PetModelTest(TestCase):
    def setUp(self):
        # 新增 PetType
        self.pet_type = PetType.objects.create(name="Dragon")
        # 新增 Pet
        self.pet = Pet.objects.create(
            name="Fire Dragon",
            normal_prop="火屬性",
            activate_prop="火焰攻擊",
            description="強大的火龍",
            type=self.pet_type
        )

    def test_pet_creation(self):
        pet = Pet.objects.get(name="Fire Dragon")
        self.assertEqual(pet.type.name, "Dragon")
        self.assertEqual(pet.description, "強大的火龍")