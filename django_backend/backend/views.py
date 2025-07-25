from django.http import JsonResponse
from rest_framework.response import Response
from .serializers import CharityEventSerializer
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
import json
from .models import PersonalInfo, CharityInfo, Location, EventType, Organization, CharityEvent
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.db.models import Q
from django.utils.decorators import method_decorator
from django.contrib.auth import authenticate, login
from datetime import datetime
from django.utils.timezone import now
from .Casino import createCasino, createBet, updateBet, removeBet, getSumOfBet, getUserWinProbability, getWinner, saveWinner
import random
import string


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
                exists = CharityInfo.objects.filter(user__email=groupEmail).exists()
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
            charityInfo = CharityInfo.objects.filter(user=user).first()
            if not charityInfo:
                return JsonResponse({'success': False, 'message': '非慈善團體用戶'}, status=401)

            data = request.data if hasattr(request, 'data') else json.loads(request.body)
            name = data.get('name')
            eventTypeName = data.get('eventType', '').strip() # 前端傳來的是typeName
            locationName = data.get('location', '').strip() # 前端傳來的是locationName(中文縣市)
            address = data.get('address', '').strip() # (中文詳細地址)
            startTime = data.get('startTime')
            endTime = data.get('endTime')
            signupDeadline = data.get('signupDeadline')
            description = data.get('description', '').strip()

            # 必填欄位檢查
            if not all([name, startTime, endTime]):
                return JsonResponse({'success': False, 'message': '缺少必填欄位(name, startTime, endTime)'}, status=400)

            mainOrganizer = charityInfo

            eventType = None
            if eventTypeName:
                eventType = EventType.objects.filter(typeName=eventTypeName).first()
                if not eventType:
                    return JsonResponse({'success': False, 'message': '找不到對應的活動類型'}, status=400)

            location = Location.objects.filter(locationName=locationName).first() if locationName else None

            # 時間格式轉換，前端傳來的是 "2025-07-24 01:03" 格式
            def parse_dt(dt_str):
                try:
                    return datetime.strptime(dt_str, "%Y-%m-%d %H:%M")
                except Exception:
                    return None

            startTimeObj = parse_dt(startTime)
            endTimeObj = parse_dt(endTime)

            if not startTimeObj or not endTimeObj:
                return JsonResponse({'success': False, 'message': '時間格式錯誤，請用 YYYY-MM-DD HH:MM'}, status=400)

            # 判斷活動狀態
            nowTime = now()
            if startTimeObj and endTimeObj:
                if nowTime < startTimeObj:
                    status = "upcoming"
                elif startTimeObj <= nowTime <= endTimeObj:
                    status = "ongoing"
                else:
                    status = "finished"
            else:
                status = "unknown"

            # 產生6位數邀請碼
            def generate_invite_code():
                while True:
                    code = ''.join(random.choices(string.digits, k=6))
                    if not CharityEvent.objects.filter(inviteCode=code).exists():
                        return code

            inviteCode = generate_invite_code()

            event = CharityEvent.objects.create(
                name=name,
                mainOrganizer=mainOrganizer,
                eventType=eventType,
                location=location,
                address=address,
                startTime=startTimeObj,
                endTime=endTimeObj,
                signupDeadline=parse_dt(signupDeadline) if signupDeadline else None,
                description=description,
                createTime=nowTime,
                status=status,
                inviteCode=inviteCode
            )

            event.save()
            return JsonResponse({'success': True, 'eventId': event.id, 'status': status}, status=201)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CharityEventList(APIView):
    """回傳活動清單(根據 request 抓到的 user 判斷是個人用戶還是組織，是組織就給組織自己的活動，個人用戶給全部的)"""

    def get(self, request, *args, **kwargs):
        user = request.user
        page = int(request.GET.get('page', 1))
        eventType = request.GET.get('eventType', None)
        location = request.GET.get('location', None)
        time = request.GET.get('time', 'permanent')
        timeDelta = settings.ACTIVITY_LIST_TIME_CHOICES.get(time, None)

        perPage = 10
        startIndex = (page - 1) * perPage
        endIndex = page * perPage

        charityInfo = CharityInfo.objects.filter(user=user).first()

        filters = Q()

        if eventType:
            filters &= Q(eventType__typeName=eventType)
        if location:
            filters &= Q(location__locationName=location)
        if timeDelta:
            nowTime = now()
            futureTime = nowTime + timeDelta
            filters &= Q(startTime__gte=nowTime, startTime__lte=futureTime)
        if charityInfo:
            filters &= Q(mainOrganizer=charityInfo)

        events = CharityEvent.objects.filter(filters).order_by('-startTime')[startIndex:endIndex]

        eventList = CharityEventSerializer(events, many=True)
        eventTypeList = list(EventType.objects.values_list('typeName', flat=True))
        locationList = list(Location.objects.values_list('locationName', flat=True))

        return Response({
            'events': eventList.data,
            'eventTypes': eventTypeList,
            'locations': locationList,
        })


@method_decorator(csrf_exempt, name='dispatch')
class CharityEventDetail(APIView):
    """根據選擇回傳對應的 event """

    def get(self, request, *args, **kwargs):
        charityEventID = kwargs.get('eventId')

        event = CharityEventSerializer(CharityEvent.objects.filter(id=charityEventID).first()).data

        return Response({
            'event': event,
        })


@method_decorator(csrf_exempt, name='dispatch')
class CoOrganize(APIView):
    """慈善團體透過邀請碼協辦 CharityEvent"""

    def post(self, request, *args, **kwargs):
        try:
            # 驗證是否登入
            user = request.user
            if not user or not user.is_authenticated:
                return JsonResponse({'success': False, 'message': '未登入'}, status=401)

            # 驗證是否為慈善團體
            charityInfo = CharityInfo.objects.filter(user=user).first()
            if not charityInfo:
                return JsonResponse({'success': False, 'message': '非慈善團體用戶'}, status=401)


            inviteCode = request.data.get('inviteCode', '').strip()
            if not inviteCode or len(inviteCode) != 6:
                return JsonResponse({'success': False, 'message': '請輸入6位數邀請碼'}, status=400)

            # 查詢 CharityEvent 是否存在
            event = CharityEvent.objects.filter(inviteCode=inviteCode).first()
            if not event:
                return JsonResponse({'success': False, 'message': '邀請碼錯誤或活動不存在'}, status=404)

            # 檢查是否已協辦
            if event.coOrganizers.filter(id=charityInfo.id).exists():
                return JsonResponse({'success': False, 'message': '已是協辦單位'}, status=400)

            # 加入協辦單位
            event.coOrganizers.add(charityInfo)
            event.save()

            return JsonResponse({'success': True, 'message': '協辦成功'}, status=200)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)
