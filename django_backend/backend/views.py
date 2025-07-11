from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import PersonalInfo, CharityInfo, Location, EventType, Organization
from rest_framework.views import APIView
from .Account import validateEmail
from django.contrib.auth.models import User
from django.utils.decorators import method_decorator
from django.contrib.auth import authenticate, login


# Create your views here.
# views.py
@csrf_exempt
def testApi(request):
    """sumary_line
    把前端傳回數字*2的結果
    Keyword arguments:
    argument -- description
    Return: 乘以2的結果
    """
    if request.method == 'POST':
        data = json.loads(request.body)
        number = data.get('number', 0)
        result = number * 2
        return JsonResponse({'result': result})
    return JsonResponse({'error': 'Invalid request'}, status=400)


@csrf_exempt
def verifyEmail(request):
    data = json.loads(request.body)

    personalEmail = data.get('personalEmail', '').strip()
    groupEmail = data.get('groupEmail', '').strip()

    if not personalEmail and not groupEmail:
        return JsonResponse({'success': False, 'message': '請輸入 email'}, status=400)

    if personalEmail:
        exists = PersonalInfo.objects.filter(user__email=personalEmail).exists()
    else:
        exists = CharityInfo.objects.filter(user__email=groupEmail).exists()

    return JsonResponse({'exists': exists}, status=200)


@csrf_exempt
def checkPersonalEmail(request):
    """B1 抓前端傳回的 email 值，驗證是否是建立過的個人 email """
    if request.method == 'POST':
        try:
            return verifyEmail(request)

        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@csrf_exempt
def checkCharityEmail(request):
    """B2 抓前端傳回的email值，驗證是否是建立過的慈善團體email"""
    if request.method == 'POST':
        try:
            return verifyEmail(request)

        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class VerifyPassword(APIView):

    def post(self, request, *args, **kwargs):
        email = request.data.get('email', "")
        password = request.data.get('password', "")
        user = authenticate(request, username=email, password=password)
        if user is not None:
            login(request, user)
            return JsonResponse({'success': True}, status=200)
        else:
            return JsonResponse({'success': False, 'message': '輸入錯誤'}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreateUser(APIView):
    """創建帳號"""

    def post(self, request, *args, **kwargs):
        try:
            accountType = request.query_params.get('type', "")

            if accountType == "personal":
                email = request.data.get('personalEmail', "")
                password = request.data.get('personalPassword', "")
                passwordConfirm = request.data.get('personalPasswordConfirm', "")

            elif accountType == "charity":
                email = request.data.get('charityEmail', "")
                password = request.data.get('charityPassword', "")
                passwordConfirm = request.data.get('charityPasswordConfirm', "")

            else:
                return JsonResponse({'success': False, 'message': '無此帳號分類'}, status=400)

            if password != passwordConfirm:
                return JsonResponse({'success': False, 'message': '密碼輸入不同，請重新輸入'}, status=400)

            user = User.objects.create_user(email=email, username=email, password=password)
            user.save()
            login(request, user)
            return JsonResponse({'success': True}, status=200)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreatePersonalInfo(APIView):
    """創建個人資料"""

    def post(self, request, *args, **kwargs):

        try:
            email = request.data.get('email', "")
            nickname = request.data.get('nickname', "")
            location = request.data.get('location', "")
            eventTypeNames = request.data.get('eventType', [])

            user = User.objects.filter(email=email).first()
            user.first_name = nickname
            user.save()

            location = Location.objects.filter(locationName=location).first()

            personalInfo = PersonalInfo.objects.create(user=user, location=location)
            personalInfo.save()

            for eventTypeName in eventTypeNames:

                eventType = EventType.objects.filter(typeName=eventTypeName).first()
                if eventType is not None:
                    personalInfo.eventType.add(eventType)

            personalInfo.save()

            return JsonResponse({'success': True}, status=200)

        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreateCharityInfo(APIView):
    """創建團體資料"""

    def post(self, request, *args, **kwargs):
        try:
            email = request.data.get('email', "")
            groupName = request.data.get('groupName', "")
            groupType = request.data.get('groupType', "")
            groupAddress = request.data.get('groupAddress', "")
            groupPhone = request.data.get('groupPhone', "")
            groupId = int(request.data.get('groupId', 0))

            user = User.objects.filter(email=email).first()
            user.first_name = groupName
            user.save()

            type = EventType.objects.filter(typeName=groupType).first()
            organization = Organization.objects.filter(code=groupId).first()

            if organization:
                charity = CharityInfo.objects.create(user=user, organization=organization)
            else:
                charity = CharityInfo.objects.create(
                    user=user, organization=organization, type=type, address=groupAddress, phone=groupPhone
                )

            charity.save()

            return JsonResponse({'success': True}, status=200)

        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)
