from django.http import JsonResponse
from rest_framework.response import Response
from .serializers import CharityEventSerializer
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
import json
from .models import PersonalInfo, CharityInfo, Location, EventType, Organization, CharityEvent, EventParticipant, QRCodeRecord, OfficialEvent
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.db.models import Q
from django.utils.decorators import method_decorator
from django.contrib.auth import authenticate, login
from datetime import datetime
from django.utils.timezone import now
from .Casino import createOrUpdateBet, getUserBetAmount, getTotalBetAmount
import random
import string
from .charityEvent import (
    createCharityEvent, coOrganizeEvent, verifyCoOrganize, getCoOrganizeApplications, removeCoOrganizer,
    editCharityEvent, deleteCharityEvent, getCoOrganizers
)
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from .mails import getMailDetail, getMailListByType


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

    permission_classes = [AllowAny]

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

    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        email = request.data.get('email', "")
        password = request.data.get('password', "")
        user = authenticate(request, username=email, password=password)
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return JsonResponse({
                'success': True,
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            },
                                status=200)
        else:
            return JsonResponse({'success': False, 'message': '輸入錯誤'}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreateUser(APIView):
    """創建帳號"""

    permission_classes = [AllowAny]

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

    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        try:
            email = request.data.get('email', "")
            nickname = request.data.get('nickname', "")
            location_name = request.data.get('location', "")
            eventTypeNames = request.data.getlist('eventType', []) # 如果是 multipart/form-data 要用 getlist

            # 找到對應的使用者
            user = User.objects.filter(email=email).first()
            if not user:
                return JsonResponse({'success': False, 'message': '找不到使用者'}, status=404)

            user.first_name = nickname
            user.save()

            # 找到對應的地區
            location = Location.objects.filter(locationName=location_name).first()

            # 建立 PersonalInfo
            personalInfo = PersonalInfo.objects.create(user=user, location=location)

            # 如果有圖片
            avatar_file = request.FILES.get('avatar')
            if avatar_file:
                personalInfo.avatar = avatar_file

            personalInfo.save()

            # 加入活動類型
            for eventTypeName in eventTypeNames:
                eventType = EventType.objects.filter(typeName=eventTypeName).first()
                if eventType:
                    personalInfo.eventType.add(eventType)

            return JsonResponse({'success': True}, status=200)

        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreateCharityInfo(APIView):
    """創建團體資料"""

    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        try:
            email = request.data.get('email', "")
            groupName = request.data.get('groupName', "")
            groupType = request.data.get('groupType', "")
            groupAddress = request.data.get('groupAddress', "")
            groupPhone = request.data.get('groupPhone', "")
            groupId = request.data.get('groupId', 0)

            organization = None
            if groupId != "":
                groupId = int(groupId)
                organization = Organization.objects.filter(code=groupId).first()

            user = User.objects.filter(email=email).first()
            user.first_name = groupName
            user.save()

            type = EventType.objects.filter(typeName=groupType).first()

            if organization:
                charity = CharityInfo.objects.create(user=user, organization=organization)
            else:
                charity = CharityInfo.objects.create(
                    user=user, organization=organization, type=type, address=groupAddress, phone=groupPhone
                )

            charity.save()

            return JsonResponse({'success': True}, status=200)

        except Exception as e:
            print(str(e))
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


"""
@method_decorator(csrf_exempt, name='dispatch')
class CreateCasino(APIView):
    給我們內部建立 5050 活動用

    def post(self, request, *args, **kwargs):
        startTime = request.data.get('startTime', None)
        endTime = request.data.get('endTime', None)
        casinoResult = createCasino(startTime=startTime, endTime=endTime)
        if casinoResult:
            return JsonResponse({'success': True}, status=200)
        return JsonResponse({'success': False, 'message': casinoResult}, status=400)
"""


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
class PersonalJoinedEventList(APIView):
    """回傳個人用戶已完成的活動清單，支援 eventType/location/time 篩選"""

    def get(self, request, *args, **kwargs):
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        page = int(request.GET.get('page', 1))
        eventType = request.GET.get('eventType', None)
        location = request.GET.get('location', None)
        time = request.GET.get('time', 'permanent')
        timeDelta = settings.ACTIVITY_LIST_TIME_CHOICES.get(time, None)

        perPage = 10
        startIndex = (page - 1) * perPage
        endIndex = page * perPage

        filters = Q(eventparticipant__personalUser=user) & Q(eventparticipant__joinType=settings.CHARITY_EVENT_FINISHED)

        if eventType:
            filters &= Q(eventType__typeName=eventType)
        if location:
            filters &= Q(location__locationName=location)
        if timeDelta:
            nowTime = now()
            futureTime = nowTime + timeDelta
            filters &= Q(startTime__gte=nowTime, startTime__lte=futureTime)

        events = CharityEvent.objects.filter(filters).distinct().order_by('-startTime')[startIndex:endIndex]
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

    permission_classes = [AllowAny]

    def get(self, request, *args, **kwargs):
        charityEventID = kwargs.get('eventId')

        event = CharityEventSerializer(CharityEvent.objects.filter(id=charityEventID).first()).data

        return Response({
            'event': event,
        })


@method_decorator(csrf_exempt, name='dispatch')
class AddCharityEventUserRecord(APIView):
    """選擇收藏/參與活動"""

    def post(self, request, *args, **kwargs):
        try:
            recordChoice = request.query_params.get('user_record_choice', "")

            user = request.user

            charityEventID = kwargs.get('eventId')

            event = CharityEvent.objects.filter(id=charityEventID).first()

            eventParticipant = EventParticipant.objects.filter(personalUser=user, charityEvent=event).first()

            if eventParticipant is not None:
                eventParticipant.joinType = recordChoice
            else:
                eventParticipant = EventParticipant.objects.create(
                    personalUser=user, charityEvent=event, joinType=recordChoice
                )

            eventParticipant.save()

            return JsonResponse({'success': True}, status=200)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)


@method_decorator(csrf_exempt, name='dispatch')
class CreateCharityEvent(APIView):
    """慈善組織創建活動"""

    def post(self, request, *args, **kwargs):
        return createCharityEvent(request)


@method_decorator(csrf_exempt, name='dispatch')
class EditCharityEvent(APIView):
    """活動主辦方編輯活動"""

    def post(self, request, *args, **kwargs):
        return editCharityEvent(request)


@method_decorator(csrf_exempt, name='dispatch')
class DeleteCharityEvent(APIView):
    """活動主辦方刪除活動"""

    def post(self, request, *args, **kwargs):
        return deleteCharityEvent(request)


@method_decorator(csrf_exempt, name='dispatch')
class CoOrganizeEvent(APIView):
    """慈善組織透過邀請碼申請協辦活動"""

    def post(self, request, *args, **kwargs):
        return coOrganizeEvent(request)


@method_decorator(csrf_exempt, name='dispatch')
class GetCoOrganizeApplications(APIView):
    """活動主辦方查詢協辦申請列表""" #只回傳 verified=None 的協辦申請者

    def post(self, request, *args, **kwargs):
        return getCoOrganizeApplications(request)


@method_decorator(csrf_exempt, name='dispatch')
class GetCoOrganizers(APIView):
    """活動主辦方查詢已認證過的協辦者列表""" #只回傳 verified=True 的協辦者

    def post(self, request, *args, **kwargs):
        return getCoOrganizers(request)

@method_decorator(csrf_exempt, name='dispatch')
class VerifyCoOrganize(APIView):
    """活動主辦方審核協辦者申請"""

    def post(self, request, *args, **kwargs):
        return verifyCoOrganize(request)


@method_decorator(csrf_exempt, name='dispatch')
class RemoveCoOrganizer(APIView):
    """活動主辦方移除協辦者"""

    def post(self, request, *args, **kwargs):
        return removeCoOrganizer(request)


@method_decorator(csrf_exempt, name='dispatch')
class ProcessUserQRCode(APIView):

    def get(self, request, *args, **kwargs):
        user = request.user
        code = random.randint(100000, 999999)
        qrcodeRecord = QRCodeRecord.objects.create(personalUser=user, token=code)
        qrcodeRecord.save()
        return JsonResponse({'success': True, 'code': code}, status=200)

    def post(self, request, *args, **kwargs):
        code = request.data.get('code', None)
        charityEventName = request.data.get('eventName', None)

        charityEvent = CharityEvent.objects.filter(name=charityEventName).first()
        codeRecord = QRCodeRecord.objects.filter(token=code).first()

        if not codeRecord.isExpired():
            user = codeRecord.personalUser

        if user:
            joined = EventParticipant.objects.filter(
                personalUser=user, charityEvent=charityEvent, joinType=settings.CHARITY_EVENT_JOIN
            ).first()
            if joined:
                joined.joinType = settings.CHARITY_EVENT_FINISHED
                joined.save()
                return JsonResponse({'success': True}, status=200)
            else:
                return JsonResponse({'success': False, 'message': '無參加資訊'}, status=404)
        else:
            return JsonResponse({'success': False, 'message': '無此code或code過期'}, status=404)


@method_decorator(csrf_exempt, name='dispatch')
class GetMailDetail(APIView):
    """查看單一郵件詳細資訊與內容"""

    def get(self, request, *args, **kwargs):
        mailId = kwargs.get('mailId')
        return getMailDetail(request, mailId)


@method_decorator(csrf_exempt, name='dispatch')
class GetMailListByType(APIView):
    """查詢user的某種type的mail list"""

    def get(self, request, *args, **kwargs):
        mailType = request.GET.get('type', '').strip()
        return getMailListByType(request, mailType)


class GetBetDetail(APIView):
    """拿到 betEvent 的下注金額"""

    def get(self, request, *args, **kwargs):
        user = request.user
        userBetAmount = getUserBetAmount(user)
        totalBetAmount = getTotalBetAmount()

        return JsonResponse({
            'success': True,
            'totalBetAmount': totalBetAmount,
            'userBetAmount': userBetAmount
        },
                            status=200)


class CreateOrUpdateBet(APIView):
    """新增 bet 紀錄"""

    def post(self, request, *args, **kwargs):

        user = request.user
        betAmount = request.data.get('betAmount', None)
        if betAmount:
            betAmount = int(betAmount)

        betEvent = OfficialEvent.objects.filter(type=settings.OFFICIAL_EVENT_TYPE_CASINO).last()

        result = createOrUpdateBet(user=user, betEvent=betEvent, betAmount=betAmount)

        if result is False:
            return JsonResponse({'success': False, 'message': '金額不夠'}, status=400)

        return JsonResponse({'success': True}, status=200)


class IsBetWinner(APIView):

    def get(self, request, *args, **kwargs):

        user = request.user
        lastEventWithWinner = OfficialEvent.objects.filter(~Q(winner=None)).order_by('-id').first()

        if lastEventWithWinner.winner == user:
            return JsonResponse({'success': True, 'isWinner': True}, status=200)
        return JsonResponse({'success': True, 'isWinner': False}, status=200)
