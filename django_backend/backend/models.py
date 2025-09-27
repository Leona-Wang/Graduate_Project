from django.db import models
from django.contrib.auth.models import User
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import uuid

# Create your models here.

# user 的設定: first_name 是暱稱，username 是 email (unique)，last_name 沒有東西，email 還是 email


class Location(models.Model):
    locationName = models.TextField(null=False)


class EventType(models.Model):
    typeName = models.TextField(null=False)


class PersonalInfo(models.Model):
    user = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    location = models.ForeignKey(Location, null=True, on_delete=models.SET_NULL)
    eventType = models.ManyToManyField(EventType, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)


class ServiceGender(models.Model):
    gender = models.TextField(null=False)


class Organization(models.Model):
    code = models.IntegerField(unique=True)
    name = models.TextField()
    CEO = models.TextField(blank=True, null=True)
    contact = models.TextField(blank=True, null=True)
    phone = models.TextField(blank=True, null=True)
    fax = models.TextField(blank=True, null=True)
    website = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    founder = models.TextField(blank=True, null=True)
    founded = models.TextField(blank=True, null=True)
    authority = models.TextField(blank=True, null=True)
    type = models.ForeignKey(EventType, blank=True, null=True, on_delete=models.SET_NULL)
    mission = models.TextField(blank=True, null=True)
    focus = models.TextField(blank=True, null=True)
    area = models.ManyToManyField(Location, blank=True)
    gender = models.ForeignKey(ServiceGender, blank=True, null=True, on_delete=models.SET_NULL)
    minAge = models.TextField(blank=True, null=True)
    maxAge = models.TextField(blank=True, null=True)
    service = models.TextField(blank=True, null=True)


class CharityInfo(models.Model):
    user = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    name = models.CharField(max_length=255)
    organization = models.ForeignKey(Organization, blank=True, null=True, on_delete=models.SET_NULL)
    type = models.ForeignKey(EventType, blank=True, null=True, on_delete=models.SET_NULL)
    address = models.TextField(blank=True, null=True)
    phone = models.TextField(blank=True, null=True)


class CharityEvent(models.Model):
    name = models.CharField(max_length=255, null=False) # 活動名稱
    mainOrganizer = models.ForeignKey(CharityInfo, on_delete=models.CASCADE, related_name="mainEvents") # 主辦單位
    coOrganizers = models.ManyToManyField(
        CharityInfo, blank=True, through='CharityEventCoOrganizer', related_name="coEvents"
    )
    eventType = models.ForeignKey(EventType, null=True, blank=True, on_delete=models.SET_NULL) # 活動類型
    location = models.ForeignKey(Location, null=True, blank=True, on_delete=models.SET_NULL) # 活動地點
    address = models.TextField(blank=True, null=True) #地址
    startTime = models.DateTimeField(null=False, blank=False) # 活動開始時間
    endTime = models.DateTimeField(null=True, blank=True) # 活動結束時間
    signupDeadline = models.DateTimeField(null=True, blank=True) # 報名截止時間
    description = models.TextField(blank=True, null=True) # 活動說明
    participants = models.ManyToManyField(User, blank=True, related_name="EventParticipant") # 參與者（報名者）
    createTime = models.DateTimeField(null=True, blank=True) # 活動上傳時間
    status = models.CharField(
        max_length=20,
        choices=settings.CHARITY_EVENT_STATUS_CHOICES,
        default=settings.CHARITY_EVENT_STATUS_UNKNOWN,
        null=True,
        blank=True
    ) # 活動狀態
    inviteCode = models.TextField(null=True, blank=True)
    online = models.BooleanField(null=True, blank=True)
    permanent = models.BooleanField(default=False) # 是否為常駐活動
    #isCanvass = models.BooleanField(default=False)


class EventParticipant(models.Model):
    personalUser = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    charityEvent = models.ForeignKey(CharityEvent, null=True, on_delete=models.SET_NULL)
    joinType = models.CharField(
        max_length=20,
        choices=settings.CHARITY_EVENT_USER_RECORD_CHOICES,
        default=settings.CHARITY_EVENT_JOIN,
    )


class CharityEventCoOrganizer(models.Model):
    charityEvent = models.ForeignKey(CharityEvent, on_delete=models.CASCADE)
    coOrganizer = models.ForeignKey(CharityInfo, on_delete=models.CASCADE)
    verified = models.BooleanField(null=True, blank=True)

    class Meta:
        db_table = "backend_charityevent_coOrganizer"


class OfficialEvent(models.Model):
    type = models.CharField(
        max_length=20,
        choices=settings.OFFICIAL_EVENT_TYPE_CHOICES,
        default=settings.OFFICIAL_EVENT_TYPE_NORMAL,
    )
    startTime = models.DateTimeField(null=True, blank=True)
    endTime = models.DateTimeField(null=True, blank=True)
    participants = models.ManyToManyField(User, through='OfficialEventParticipant', related_name='officialEvents')
    winner = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL)


class OfficialEventParticipant(models.Model):
    user = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    officialEvent = models.ForeignKey(OfficialEvent, null=True, on_delete=models.SET_NULL)
    betAmount = models.IntegerField()


class QRCodeRecord(models.Model):
    personalUser = models.ForeignKey(User, on_delete=models.CASCADE) # 持有人
    createTime = models.DateTimeField(auto_now_add=True) # 生成時間
    expireTime = models.DateTimeField() # 過期時間
    isUsed = models.BooleanField(default=False) #
    token = models.CharField(max_length=64, unique=True)

    def isExpired(self):
        return timezone.now() > self.expireTime

    def save(self, *args, **kwargs):
        # 預設 QRCode 有效期限為 5 分鐘
        if not self.expireTime:
            self.expireTime = self.createTime + timedelta(minutes=5)
        super().save(*args, **kwargs)


class LetterType(models.Model):
    type = models.CharField(max_length=10, null=False, blank=False)


class Letter(models.Model):
    receiver = models.ForeignKey(
        User, null=True, blank=True, on_delete=models.SET_NULL, related_name="receivedLetters"
    ) # 收件人
    date = models.DateTimeField(auto_now_add=True) # 寄信日期
    type = models.ForeignKey(LetterType, null=True, blank=True, on_delete=models.SET_NULL) # 信件類型
    title = models.CharField(max_length=255, null=False, blank=False) # 標題
    content = models.TextField(null=False, blank=False) # 內容
    isRead = models.BooleanField(default=False) # 是否已讀
    charityEvent = models.ForeignKey(
        'CharityEvent', null=True, blank=True, on_delete=models.CASCADE, related_name="letters"
    )
    officialEvent = models.ForeignKey(
        'OfficialEvent', null=True, blank=True, on_delete=models.CASCADE, related_name="letters"
    )


class Attribute(models.Model):
    name = models.CharField(
        max_length=20,
        choices=settings.ATTRIBUTE_CHOICES,
        default=settings.ATTRIBUTE_WHOLE,
    )


class ItemType(models.Model):
    type = models.CharField(
        max_length=20,
        choices=settings.ITEM_CHOICES,
        default=settings.ITEM_CASH,
    )


class Item(models.Model): #金幣與道具
    itemName = models.CharField(max_length=20, null=False, blank=False) # 物品名稱
    itemType = models.ForeignKey(ItemType, null=True, on_delete=models.SET_NULL)
    itemAttribute = models.ForeignKey(Attribute, null=True, blank=True, on_delete=models.SET_NULL)
    point = models.IntegerField(null=True, blank=True) #加多少親密點數


class ItemBox(models.Model): #用戶持有的金幣跟道具
    personalInfo = models.ForeignKey(PersonalInfo, null=True, on_delete=models.SET_NULL)
    item = models.ForeignKey(Item, null=True, on_delete=models.SET_NULL)
    quantity = models.IntegerField()


class Reward(models.Model): #辦完活動的獎勵&fifty fifty
    prize = models.ForeignKey(Item, null=True, blank=False, on_delete=models.SET_NULL) # 對應獎品
    receiver = models.ForeignKey(User, null=True, blank=False, on_delete=models.SET_NULL) # 得獎者
    quantity = models.IntegerField() # 個數


class Pet(models.Model):
    name = models.CharField(max_length=20, null=False, blank=False)
    attribute = models.ForeignKey(Attribute, null=True, on_delete=models.SET_NULL)
    description = models.TextField(null=True, blank=True)
    fullPoint = models.IntegerField() #最多累積的親密點數


class PersonalPet(models.Model):
    personalInfo = models.ForeignKey(PersonalInfo, null=True, on_delete=models.SET_NULL)
    pet = models.ForeignKey(Pet, null=True, on_delete=models.SET_NULL)
    currentPoint = models.IntegerField()
