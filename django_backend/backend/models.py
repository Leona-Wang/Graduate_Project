from django.db import models
from django.contrib.auth.models import User

# Create your models here.


class PersonalInfo(models.Model):
    """這裡蒐集的資料不該這麼少，再跟前端討論加 tag 、聯絡方式之類的"""
    user = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)


class EventType(models.Model):
    typeName = models.TextField(null=False)


class Location(models.Model):
    locationName = models.TextField(null=False)


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


class OrganizationArea(models.Model):
    organization = models.ForeignKey(Organization, blank=True, null=True, on_delete=models.SET_NULL)
    location = models.ForeignKey(Location, blank=True, null=True, on_delete=models.SET_NULL)


class CharityInfo(models.Model):
    organization = models.ForeignKey(Organization, blank=True, null=True, on_delete=models.SET_NULL)
