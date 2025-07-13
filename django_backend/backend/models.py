from django.db import models
from django.contrib.auth.models import User

# Create your models here.


class Location(models.Model):
    locationName = models.TextField(null=False)
    latitude = models.FloatField(null=True, blank=True)  # 緯度
    longitude = models.FloatField(null=True, blank=True)  # 經度


class EventType(models.Model):
    typeName = models.TextField(null=False)


class PersonalInfo(models.Model):
    user = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    location = models.ForeignKey(Location, null=True, on_delete=models.SET_NULL)
    eventType = models.ManyToManyField(EventType, blank=True)


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
    organization = models.ForeignKey(Organization, blank=True, null=True, on_delete=models.SET_NULL)
    type = models.ForeignKey(EventType, blank=True, null=True, on_delete=models.SET_NULL)
    address = models.TextField(blank=True, null=True)
    phone = models.TextField(blank=True, null=True)
    
class CharityEvent(models.Model):
    name = models.CharField(max_length=255)  # 活動名稱
    mainOrganizer = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name="mainEvents")  # 主辦單位
    coOrganizers = models.ManyToManyField(Organization, blank=True, related_name="coEvents")  # 協辦單位
    eventType = models.ForeignKey(EventType, null=True, blank=True, on_delete=models.SET_NULL)  # 活動類型
    location = models.ForeignKey(Location, null=True, blank=True, on_delete=models.SET_NULL)  # 活動地點
    startTime = models.DateTimeField(null=False, blank=False)  # 活動開始時間
    endTime = models.DateTimeField(null=False, blank=False)    # 活動結束時間
    signupDeadline = models.DateTimeField(null=True, blank=True)  # 報名截止時間
    #image = models.ImageField(upload_to='eventImages/', null=True, blank=True)  # 活動圖片
    description = models.TextField(blank=True, null=True)  # 活動說明
    participants = models.ManyToManyField(User, blank=True)  # 參與者（報名者）
    createTime = models.DateTimeField(null=True, blank=True)  # 活動上傳時間
    status = models.TextField(null=True, blank=True)  #活動狀態


