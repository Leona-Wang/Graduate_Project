from django.db import models
from django.contrib.auth.models import User

# Create your models here.


class Location(models.Model):
    locationName = models.TextField(null=False)


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
