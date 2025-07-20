from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import PersonalInfo, CharityInfo, Location, EventType, Organization, CharityEvent
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.utils.decorators import method_decorator
from django.contrib.auth import authenticate, login
from datetime import datetime
from .Casino import createCasino, createBet, updateBet, removeBet, getSumOfBet, getUserWinProbability, getWinner, saveWinner


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


@method_decorator(csrf_exempt, name='dispatch')
class CheckEmail(APIView):
    """根據 query string 的 type 來驗證個人或慈善 email"""

    def post(self, request, *args, **kwargs):
        try:
            type_ = request.query_params.get('type', '').lower()
            if type_ == 'personal':
                personalEmail = request.data.get('personalEmail', '').strip()
                if not personalEmail:
                    return JsonResponse({'success': False, 'message': '請輸入個人 email'}, status=400)
                exists = PersonalInfo.objects.filter(user__email=personalEmail).exists()
                return JsonResponse({'exists': exists}, status=200)
            elif type_ == 'charity':
                groupEmail = request.data.get('groupEmail', '').strip()
                if not groupEmail:
                    return JsonResponse({'success': False, 'message': '請輸入團體 email'}, status=400)
                exists = CharityInfo.objects.filter(organization__email=groupEmail).exists()
                return JsonResponse({'exists': exists}, status=200)
            else:
                return JsonResponse({'success': False, 'message': 'type 必須為 personal 或 charity'}, status=400)
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


@method_decorator(csrf_exempt, name='dispatch')
class CreateCasino(APIView):
    """給我們內部建立 5050 活動用"""

    def post(self, request, *args, **kwargs):
        startTime = request.data.get('startTime', None)
        endTime = request.data.get('endTime', None)
        casinoResult = createCasino(startTime=startTime, endTime=endTime)
        if casinoResult:
            return JsonResponse({'success': True}, status=200)
        return JsonResponse({'success': False, 'message': casinoResult}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreateCharityEvent(APIView):
    """慈善團體用戶新增 CharityEvent"""

    def post(self, request, *args, **kwargs):
        try:
            # 驗證是否登入
            user = request.user
            if not user or not user.is_authenticated:
                return JsonResponse({'success': False, 'message': '未登入'}, status=401)

            # 驗證是否為慈善團體
            charity_info = CharityInfo.objects.filter(user=user).first()
            if not charity_info:
                return JsonResponse({'success': False, 'message': '非慈善團體用戶'}, status=401)

            data = request.data if hasattr(request, 'data') else json.loads(request.body)
            name = data.get('name', '').strip()
            coOrganizerIds = data.get('coOrganizers', [])
            eventTypeId = data.get('eventType')
            locationId = data.get('location')
            address = data.get('address', '')
            startTime = data.get('startTime')
            endTime = data.get('endTime')
            signupDeadline = data.get('signupDeadline')
            description = data.get('description', '')
            participantIds = data.get('participants', [])
            createTime = data.get('createTime')
            status = data.get('status', '')

            # 必填欄位檢查
            if not all([name, startTime, endTime]):
                return JsonResponse({'success': False, 'message': '缺少必填欄位(name, startTime, endTime)'}, status=400)

            mainOrganizer = charity_info.organization
            if not mainOrganizer:
                return JsonResponse({'success': False, 'message': '慈善團體缺少主辦單位'}, status=400)

            eventType = EventType.objects.filter(id=eventTypeId).first() if eventTypeId else None
            location = Location.objects.filter(id=locationId).first() if locationId else None

            # 時間格式轉換
            def parse_dt(dt_str):
                return datetime.fromisoformat(dt_str) if dt_str else None

            event = CharityEvent.objects.create(
                name=name,
                mainOrganizer=mainOrganizer,
                eventType=eventType,
                location=location,
                address=address,
                startTime=parse_dt(startTime),
                endTime=parse_dt(endTime),
                signupDeadline=parse_dt(signupDeadline) if signupDeadline else None,
                description=description,
                createTime=parse_dt(createTime) if createTime else None,
                status=status
            )

            # 協辦單位
            if coOrganizerIds:
                coOrganizers = Organization.objects.filter(id__in=coOrganizerIds)
                event.coOrganizers.set(coOrganizers)

            # 參與者
            if participantIds:
                participants = User.objects.filter(id__in=participantIds)
                event.participants.set(participants)

            event.save()
            return JsonResponse({'success': True, 'eventId': event.id}, status=201)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)
