from django.http import JsonResponse
from django.utils.timezone import now
from datetime import datetime
import random
import string
from .models import CharityInfo, CharityEvent, CharityEventCoOrganizer, EventType, Location

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
        endTime = data.get('endTime')
        signupDeadline = data.get('signupDeadline')
        description = data.get('description', '').strip()

        if not all([name, startTime, endTime]):
            return JsonResponse({'success': False, 'message': '缺少必填欄位(name, startTime, endTime)'}, status=400)

        mainOrganizer = charityInfo

        eventType = None
        if eventTypeName:
            eventType = EventType.objects.filter(typeName=eventTypeName).first()
            if not eventType:
                return JsonResponse({'success': False, 'message': '找不到對應的活動類型'}, status=400)

        location = Location.objects.filter(locationName=locationName).first() if locationName else None

        def parseDt(dt_str):
            try:
                return datetime.strptime(dt_str, "%Y-%m-%d %H:%M")
            except Exception:
                return None

        startTimeObj = parseDt(startTime)
        endTimeObj = parseDt(endTime)

        if not startTimeObj or not endTimeObj:
            return JsonResponse({'success': False, 'message': '時間格式錯誤，請用 YYYY-MM-DD HH:MM'}, status=400)

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
            signupDeadline=parseDt(signupDeadline) if signupDeadline else None,
            description=description,
            createTime=nowTime,
            status=status,
            inviteCode=inviteCode
        )

        event.save()
        return JsonResponse({'success': True, 'eventId': event.id, 'status': status}, status=200)
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
            CharityEventCoOrganizer.objects.create(
                charityEvent=event,
                coOrganizer=charityInfo,
                verified=None
            )
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

        # 查詢所有協辦申請
        applications = CharityEventCoOrganizer.objects.filter(charityEvent=event)
        result = []
        for app in applications:
            result.append({
                'coOrganizerName': app.coOrganizer.name,
                'coOrganizerEmail': app.coOrganizer.user.email if app.coOrganizer.user else '',
                'verified': app.verified,  # None=待審核, True=通過, False=不通過
            })

        return JsonResponse({'success': True, 'applications': result}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)