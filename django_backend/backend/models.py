from django.db import models

print(">>> backend.models 被載入")


# Create your models here.
class User(models.Model):
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=10, unique=True)
    password = models.CharField(max_length=128)  # 建議設大一點，存加密值
    identity = models.CharField(max_length=10)
    group_type = models.CharField(max_length=10)
    group_id = models.CharField(max_length=20)
    group_address = models.CharField(max_length=50)
    group_phone = models.CharField(max_length=20)

    def __str__(self):
        return f"{self.name} ({self.email})"

class PetType(models.Model):
    name = models.CharField(max_length=30)

    def __str__(self):
        return self.name

class Pet(models.Model):
    name = models.CharField(max_length=50)
    normal_prop = models.TextField(blank=True)
    activate_prop = models.TextField(blank=True)
    description = models.TextField(blank=True)
    type = models.ForeignKey(PetType, on_delete=models.CASCADE)
    evo_pet = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.name

class PetList(models.Model):
    amount = models.PositiveIntegerField()
    pet = models.ForeignKey(Pet, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.name}'s {self.pet.name} x {self.amount}"

class ItemGroup(models.Model):
    name = models.CharField(max_length=50)

    def __str__(self):
        return self.name

class Item(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    cost = models.DecimalField(max_digits=10, decimal_places=2)
    unit = models.CharField(max_length=20)
    group = models.ForeignKey(ItemGroup, on_delete=models.CASCADE)
    type = models.ForeignKey(PetType, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.name

class ItemList(models.Model):
    amount = models.PositiveIntegerField()
    item = models.ForeignKey(Item, on_delete=models.CASCADE)
    user = models.ForeignKey('User', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.name}'s {self.item.name} x {self.amount}"
    
class MissionGroup(models.Model):
    name = models.CharField(max_length=50)

    def __str__(self):
        return self.name

class Mission(models.Model):
    name = models.CharField(max_length=100)
    location = models.CharField(max_length=100)
    time = models.DateTimeField()
    description = models.TextField(blank=True)
    user = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True)  # 指派者
    type = models.ForeignKey('PetType', on_delete=models.SET_NULL, null=True, blank=True)  # 任務類型
    group = models.ForeignKey(MissionGroup, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.name

class MissionList(models.Model):
    user = models.ForeignKey('User', on_delete=models.CASCADE)
    mission = models.ForeignKey(Mission, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.name} -> {self.mission.name}"
    