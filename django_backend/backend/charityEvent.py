import json
from django.http import JsonResponse
from django.utils.timezone import now
from datetime import datetime
import random
import string
from .models import CharityInfo, CharityEvent, CharityEventCoOrganizer, EventType, Location, EventParticipant, Letter
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.decorators import api_view, permission_classes
from django.utils import timezone
from django.conf import settings
from django.template import loader


def createCharityEvent(request):

    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        charityInfo = CharityInfo.objects.filter(user=user).first()
        if not charityInfo:
            return JsonResponse({'success': False, 'message': '非慈善團體用戶'}, status=401)

        data = request.data if hasattr(request, 'data') else json.loads(request.body)
        name = data.get('name')
        eventTypeName = data.get('eventType', '').strip()
        locationName = data.get('location', '').strip()
        address = data.get('address', '').strip()
        startTime = data.get('startTime')
        endTime = data.get('endTime', None)
        signupDeadline = data.get('signupDeadline', None)
        description = data.get('description', '').strip()
        online = data.get('online', False)
        permanent = data.get('permanent', False)

        if not all([name, startTime]):
            return JsonResponse({'success': False, 'message': '缺少必填欄位(name, startTime)'}, status=400)

        mainOrganizer = charityInfo

        eventType = None
        if eventTypeName:
            eventType = EventType.objects.filter(typeName=eventTypeName).first()
            if not eventType:
                return JsonResponse({'success': False, 'message': '找不到對應的活動類型'}, status=400)

        # 判斷是否為線上活動
        if online:
            location = None
            address = None
        else:
            location = Location.objects.filter(locationName=locationName).first() if locationName else None

        def parseDt(dtStr):
            if not dtStr:
                return None
            try:
                naiveDt = datetime.strptime(dtStr, "%Y-%m-%d %H:%M")
                return timezone.make_aware(naiveDt)
            except Exception:
                return None

        startTimeObj = parseDt(startTime)
        endTimeObj = parseDt(endTime) if endTime else None

        if not startTimeObj:
            return JsonResponse({'success': False, 'message': '時間格式錯誤，請用 YYYY-MM-DD HH:MM'}, status=400)

        nowTime = now()
        if startTimeObj and endTimeObj:
            if nowTime < startTimeObj:
                status = settings.CHARITY_EVENT_STATUS_UPCOMING
            elif startTimeObj <= nowTime <= endTimeObj:
                status = settings.CHARITY_EVENT_STATUS_ONGOING
            else:
                status = settings.CHARITY_EVENT_STATUS_FINISHED
        elif startTimeObj:
            if nowTime < startTimeObj:
                status = settings.CHARITY_EVENT_STATUS_UPCOMING
            else:
                status = settings.CHARITY_EVENT_STATUS_ONGOING
        else:
            status = settings.CHARITY_EVENT_STATUS_UNKNOWN

        def generateInviteCode():
            while True:
                code = ''.join(random.choices(string.digits, k=6))
                if not CharityEvent.objects.filter(inviteCode=code).exists():
                    return code

        inviteCode = generateInviteCode()

        event = CharityEvent.objects.create(
            name=name,
            mainOrganizer=mainOrganizer,
            eventType=eventType,
            location=location,
            address=address,
            startTime=startTimeObj,
            endTime=endTimeObj,
            signupDeadline=parseDt(signupDeadline),
            description=description,
            createTime=nowTime,
            status=status,
            inviteCode=inviteCode,
            online=online,
            permanent=permanent
        )

        event.save()
        status_display = settings.CHARITY_EVENT_STATUS_DISPLAY.get(status, status)
        return JsonResponse({'success': True, 'eventId': event.id, 'status': status_display}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def editCharityEvent(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        data = request.data if hasattr(request, 'data') else json.loads(request.body)
        eventName = data.get('name', '').strip()
        if not eventName:
            return JsonResponse({'success': False, 'message': '缺少活動名稱'}, status=400)

        # 查詢 CharityEvent
        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 驗證主辦方身分
        if not CharityInfo.objects.filter(user=user, id=event.mainOrganizer_id).exists():
            return JsonResponse({'success': False, 'message': '只有主辦方可以編輯活動'}, status=403)

        # 允許更新的欄位
        eventTypeName = data.get('eventType', None)
        locationName = data.get('location', None)
        address = data.get('address', None)
        startTime = data.get('startTime', None)
        endTime = data.get('endTime', None)
        signupDeadline = data.get('signupDeadline', None)
        description = data.get('description', None)
        online = data.get('online', None)
        permanent = data.get('permanent', None)

        # eventType
        if eventTypeName is not None:
            eventType = EventType.objects.filter(typeName=eventTypeName).first()
            if not eventType:
                return JsonResponse({'success': False, 'message': '找不到對應的活動類型'}, status=400)
            event.eventType = eventType

        # 線上活動判斷
        if online is not None:
            event.online = online
            if online:
                event.location = None
                event.address = None
            else:
                if locationName is not None:
                    location = Location.objects.filter(locationName=locationName).first()
                    event.location = location
                if address is not None:
                    event.address = address
        else:
            if locationName is not None:
                location = Location.objects.filter(locationName=locationName).first()
                event.location = location
            if address is not None:
                event.address = address

        # 其他欄位
        if startTime is not None:
            event.startTime = datetime.strptime(startTime, "%Y-%m-%d %H:%M")
        if endTime is not None:
            if endTime == "" or endTime is None:
                event.endTime = None
            else:
                event.endTime = datetime.strptime(endTime, "%Y-%m-%d %H:%M")
        if signupDeadline is not None:
            if signupDeadline == "" or signupDeadline is None:
                event.signupDeadline = None
            else:
                event.signupDeadline = datetime.strptime(signupDeadline, "%Y-%m-%d %H:%M")
        if description is not None:
            event.description = description
        if permanent is not None:
            event.permanent = permanent

        event.save()
        return JsonResponse({'success': True, 'message': '活動已更新'}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def deleteCharityEvent(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        data = request.data if hasattr(request, 'data') else json.loads(request.body)
        eventName = data.get('eventName', '').strip()
        if not eventName:
            return JsonResponse({'success': False, 'message': '缺少活動名稱'}, status=400)

        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 驗證主辦方身分
        if not CharityInfo.objects.filter(user=user, id=event.mainOrganizer_id).exists():
            return JsonResponse({'success': False, 'message': '只有主辦方可以刪除活動'}, status=403)

        # 查詢收藏者、報名者、協辦者
        saves = EventParticipant.objects.filter(charityEvent=event, joinType=settings.CHARITY_EVENT_SAVE)
        joins = EventParticipant.objects.filter(charityEvent=event, joinType=settings.CHARITY_EVENT_JOIN)
        co_orgs = CharityEventCoOrganizer.objects.filter(charityEvent=event, verified=True)

        charityName = event.mainOrganizer.name
        eventName = event.name

        # 載入信件模板
        titleTemplate = loader.get_template('EventDeletedLetterTitle.txt')
        savedContentTemplate = loader.get_template('SavedEventDeletedLetterContent.txt')
        joinedContentTemplate = loader.get_template('JoinedEventDeletedLetterContent.txt')
        coOrgContentTemplate = loader.get_template('CoOrganizeEventDeletedLetterContent.txt')

        letters = []

        # 寄給收藏者
        for save in saves:
            title = titleTemplate.render({}).strip()
            content = savedContentTemplate.render({
                'username': save.personalUser.first_name,
                'charityName': charityName,
                'eventName': eventName,
            }).strip()
            letter = Letter(
                receiver=save.personalUser,
                title=title,
                content=content,
                charityEvent=event
            )
            letters.append(letter)

        # 寄給報名者
        for join in joins:
            title = titleTemplate.render({}).strip()
            content = joinedContentTemplate.render({
                'username': join.personalUser.first_name,
                'charityName': charityName,
                'eventName': eventName,
            }).strip()
            letter = Letter(
                receiver=join.personalUser,
                title=title,
                content=content,
                charityEvent=event
            )
            letters.append(letter)

        # 寄給協辦者
        for co_org in co_orgs:
            co_organizer = co_org.coOrganizer
            title = titleTemplate.render({}).strip()
            content = coOrgContentTemplate.render({
                'username': co_organizer.name,
                'charityName': charityName,
                'eventName': eventName,
            }).strip()
            letter = Letter(
                receiver=co_organizer.user,
                title=title,
                content=content,
                charityEvent=event
            )
            letters.append(letter)

        # 批次建立信件
        if letters:
            Letter.objects.bulk_create(letters)

        event.delete()

        return JsonResponse({'success': True, 'message': '活動已刪除，已通知收藏者、報名者與協辦者'}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def coOrganizeEvent(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        charityInfo = CharityInfo.objects.filter(user=user).first()
        if not charityInfo:
            return JsonResponse({'success': False, 'message': '非慈善團體用戶'}, status=401)

        inviteCode = request.data.get('inviteCode', '').strip()
        if not inviteCode or len(inviteCode) != 6:
            return JsonResponse({'success': False, 'message': '請輸入6位數邀請碼'}, status=400)

        event = CharityEvent.objects.filter(inviteCode=inviteCode).first()
        if not event:
            return JsonResponse({'success': False, 'message': '邀請碼錯誤或活動不存在'}, status=404)

        # 檢查是否已申請過
        co_org = CharityEventCoOrganizer.objects.filter(charityEvent=event, coOrganizer=charityInfo).first()
        if co_org:
            if co_org.verified is True:
                return JsonResponse({'success': False, 'message': '已是協辦單位'}, status=400)
            elif co_org.verified is None:
                return JsonResponse({'success': False, 'message': '已申請協辦，請等待主辦方審核'}, status=400)
            elif co_org.verified is False:
                # 允許重新申請，更新 verified=None
                co_org.verified = None
                co_org.save()
                return JsonResponse({'success': True, 'message': '重新申請協辦成功，請等待主辦方審核'}, status=200)
        else:
            # 建立新申請，verified=None
            CharityEventCoOrganizer.objects.create(charityEvent=event, coOrganizer=charityInfo, verified=None)
            return JsonResponse({'success': True, 'message': '協辦申請已送出，請等待主辦方審核'}, status=200)

    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def verifyCoOrganize(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        eventName = request.data.get('charityEventName', '').strip()
        coOrganizerName = request.data.get('coOrganizerName', '').strip()
        approve = request.data.get('approve', None)

        if not eventName or not coOrganizerName or approve is None:
            return JsonResponse({'success': False, 'message': '缺少必要參數eventName或coOrganizerName或approve'}, status=400)

        # 查詢 CharityEvent
        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 驗證主辦方身分
        if not CharityInfo.objects.filter(user=user, id=event.mainOrganizer_id).exists():
            return JsonResponse({'success': False, 'message': '只有主辦方可以審核協辦申請'}, status=403)

        # 查詢協辦 CharityInfo
        co_organizer = CharityInfo.objects.filter(name=coOrganizerName).first()
        if not co_organizer:
            return JsonResponse({'success': False, 'message': '查無此協辦單位'}, status=404)

        # 查詢協辦申請
        co_org = CharityEventCoOrganizer.objects.filter(charityEvent=event, coOrganizer=co_organizer).first()
        if not co_org:
            return JsonResponse({'success': False, 'message': '查無此協辦申請'}, status=404)

        if co_org.verified is not None:
            return JsonResponse({'success': False, 'message': '該申請已審核過'}, status=400)

        # 審核
        co_org.verified = bool(approve)
        co_org.save()

        msg = '審核通過' if co_org.verified else '審核不通過'
        return JsonResponse({'success': True, 'message': msg}, status=200)

    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def getCoOrganizeApplications(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        eventName = request.data.get('charityEventName', '').strip()
        if not eventName:
            return JsonResponse({'success': False, 'message': '缺少活動名稱'}, status=400)

        # 查詢 CharityEvent
        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 驗證主辦方身分
        if not CharityInfo.objects.filter(user=user, id=event.mainOrganizer_id).exists():
            return JsonResponse({'success': False, 'message': '只有主辦方可以查詢協辦申請'}, status=403)

        # 只查詢 verified=None 的協辦申請（尚未審核）
        applications = CharityEventCoOrganizer.objects.filter(charityEvent=event, verified=None)
        result = []
        for app in applications:
            result.append({
                'coOrganizerName': app.coOrganizer.name,
                'coOrganizerEmail': app.coOrganizer.user.email if app.coOrganizer.user else '',
            })

        return JsonResponse({'success': True, 'applications': result}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def getCoOrganizers(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        eventName = request.data.get('eventName', '').strip()
        if not eventName:
            return JsonResponse({'success': False, 'message': '缺少活動名稱'}, status=400)

        # 查詢 CharityEvent
        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 查詢 verified=True 的協辦者
        co_orgs = CharityEventCoOrganizer.objects.filter(charityEvent=event, verified=True)
        result = []
        for co_org in co_orgs:
            result.append({
                'coOrganizerName': co_org.coOrganizer.name,
                'coOrganizerEmail': co_org.coOrganizer.user.email if co_org.coOrganizer.user else '',
            })

        return JsonResponse({'success': True, 'coOrganizers': result}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def removeCoOrganizer(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        eventName = request.data.get('charityEventName', '').strip()
        coOrganizerName = request.data.get('coOrganizerName', '').strip()

        if not eventName or not coOrganizerName:
            return JsonResponse({'success': False, 'message': '缺少活動名稱或協辦者名稱'}, status=400)

        # 查詢 CharityEvent
        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 驗證主辦方身分
        if not CharityInfo.objects.filter(user=user, id=event.mainOrganizer_id).exists():
            return JsonResponse({'success': False, 'message': '只有主辦方可以踢除協辦者'}, status=403)

        # 查詢協辦 CharityInfo
        co_organizer = CharityInfo.objects.filter(name=coOrganizerName).first()
        if not co_organizer:
            return JsonResponse({'success': False, 'message': '查無此協辦者'}, status=404)

        # 查詢協辦申請
        co_org = CharityEventCoOrganizer.objects.filter(charityEvent=event, coOrganizer=co_organizer).first()
        if not co_org or co_org.verified is not True:
            return JsonResponse({'success': False, 'message': '該協辦者目前不是認證協辦者'}, status=400)

        # 踢除協辦者
        co_org.verified = False
        co_org.save()

        return JsonResponse({'success': True, 'message': '該協辦者已被踢除'}, status=200)

    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)



