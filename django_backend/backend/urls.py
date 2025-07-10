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
    path('checkPersonalEmail/', views.checkPersonalEmail),
    path('checkCharityEmail/', views.checkCharityEmail),
    path('login/', views.VerifyPassword.as_view(), name="verifyPassword"),
    path('user/create/', views.CreateUser.as_view(), name="createUser"),
    path('person/create/', views.CreatePersonalInfo.as_view(), name="createPersonalInfo"),
    path('charity/create/', views.CreateCharityInfo.as_view(), name="createCharityInfo"),
]
