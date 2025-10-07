"""
URL configuration for django_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path
from . import views

urlpatterns = [
    path('testApi/', views.testApi),
    path('email/check/', views.CheckEmail.as_view(), name="checkEmail"),
    path('login/', views.VerifyPassword.as_view(), name="verifyPassword"),
    path('user/create/', views.CreateUser.as_view(), name="createUser"),
    path('person/create/', views.CreatePersonalInfo.as_view(), name="createPersonalInfo"),
    path('charity/create/', views.CreateCharityInfo.as_view(), name="createCharityInfo"),
    path('charity/event/create/', views.CreateCharityEvent.as_view(), name="createCharityEvent"),
    path('charity/event/edit/', views.EditCharityEvent.as_view(), name="editCharityEvent"),
    path('charity/event/delete/', views.DeleteCharityEvent.as_view(), name="deleteCharityEvent"),
    path('charity/event/coorganize/', views.CoOrganizeEvent.as_view(), name="coOrganizeEvent"),
    path(
        'charity/event/coorganize/applications/',
        views.GetCoOrganizeApplications.as_view(),
        name="getCoOrganizeApplications"
    ),
    path('charity/event/coorganizers/', views.GetCoOrganizers.as_view(), name="getCoOrganizers"),
    path('charity/event/coorganize/verify/', views.VerifyCoOrganize.as_view(), name="verifyCoOrganize"),
    path('charity/event/coorganize/remove/', views.RemoveCoOrganizer.as_view(), name="removeCoOrganizer"),
    path('events/', views.CharityEventList.as_view(), name="charityEventList"),
    path('events/personal_joined/', views.PersonalJoinedEventList.as_view(), name="personalJoinedEventList"),
    path('events/<int:eventId>/', views.CharityEventDetail.as_view(), name="charityEventDetail"),
    path(
        'events/<int:eventId>/participant_record/',
        views.AddCharityEventUserRecord.as_view(),
        name="addCharityEventUserRecord"
    ),
    path('events/user_QRCode/', views.ProcessUserQRCode.as_view(), name="ProcessUserQRCode"),
    path('mail/<int:mailId>/', views.GetMailDetail.as_view(), name="mailDetail"),
    path('mail/<int:mailId>/reward/', views.SendReward.as_view(), name="sendReward"),
    path('mail/list/', views.GetMailListByType.as_view(), name="mailListByType"),
    path('events/casino/', views.GetBetDetail.as_view(), name="getBetDetail"),
    path('events/casino/bet_amount/edit/', views.CreateOrUpdateBet.as_view(), name="createOrUpdateBet"),
    path('pet/powerup/', views.getPowerupList.as_view(), name="getPowerupList"),
    path('pet/powerup/edit/', views.deductPowerup.as_view(), name="deductPowerup"),
    path('pets/all/', views.GetAllPets.as_view(), name="getAllPets"),
    path('pets/<int:petId>/', views.PetDetail.as_view(), name="petDetail"),
    path('pets/gacha/', views.GachaPet.as_view(), name="gachaPet"),
]
