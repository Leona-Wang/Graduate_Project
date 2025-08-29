from jinja2 import Template
from .models import Letter, LetterType, LetterExample, CharityEvent
from django.http import JsonResponse
import json


def getMailDetail(request, mailId):
    try:
        mail = Letter.objects.filter(id=mailId).first()
        if not mail:
            return JsonResponse({'success': False, 'message': '查無此信件'}, status=404)

        # 該信件設為已讀
        if not mail.isRead:
            mail.isRead = True
            mail.save()

        # 時間轉換為 'YYYY-MM-DD HH:MM' 格式
        date_str = mail.date.strftime('%Y-%m-%d %H:%M') if mail.date else None

        result = {
            'id': mail.id,
            'receiver': mail.receiver.first_name if mail.receiver else None,
            'date': date_str,
            'type': mail.type.type if mail.type else None,
            'title': mail.title,
            'content': mail.content,
            'isRead': mail.isRead,
        }
        return JsonResponse({'success': True, 'mail': result}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

def getMailListByType(request, mailType):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        if not mailType:
            return JsonResponse({'success': False, 'message': '缺少信件類型'}, status=400)

        # 查詢信件類型
        letter_type = LetterType.objects.filter(type=mailType).first()
        if not letter_type:
            return JsonResponse({'success': False, 'message': '查無此信件類型'}, status=404)

        # 查詢該用戶該類型所有信件
        mails = Letter.objects.filter(receiver=user, type=letter_type).order_by('-date')
        mail_list = [
            {
                'id': mail.id,
                'title': mail.title,
                'isRead': mail.isRead
            }
            for mail in mails
        ]

        return JsonResponse({'success': True, 'mails': mail_list}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)
    
def sendPersonalCanvassMail(request):
    try:
        data = request.data if hasattr(request, 'data') else json.loads(request.body)
        eventName = data.get('eventName', '').strip()
        isCanvass = data.get('isCanvass', None)

        if not eventName or isCanvass is None:
            return JsonResponse({'success': False, 'message': '缺少參數'}, status=400)

        event = CharityEvent.objects.filter(name=eventName).first()
        if not event:
            return JsonResponse({'success': False, 'message': '查無此活動'}, status=404)

        # 驗證主辦方身分
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)
        if not event.mainOrganizer.user == user:
            return JsonResponse({'success': False, 'message': '只有活動主辦方可以操作'}, status=403)

        # 設定 isCanvass 狀態
        event.isCanvass = bool(isCanvass)
        event.save()

        if isCanvass:
            # 找到信件模板
            template_obj = LetterExample.objects.filter(templateName="personalCanvass").first()
            if not template_obj:
                return JsonResponse({'success': False, 'message': '查無個人催票信模板'}, status=404)

            canvass_type = LetterType.objects.filter(type="canvass").first()
            if not canvass_type:
                canvass_type = LetterType.objects.create(type="canvass")

            receivers = event.recommendedBy.all()
            for receiver in receivers:
                # startTime 格式轉換
                if event.startTime:
                    dt = event.startTime
                    start_time_str = f"{dt.year}年{dt.month}月{dt.day}日 {dt.hour}時{dt.minute}分"
                else:
                    start_time_str = ""

                # jinja2 context
                context = {
                    "receiver": {"first_name": receiver.first_name},
                    "CharityEvent": {
                        "name": event.name,
                        "startTime": start_time_str
                    }
                }
                title = Template(template_obj.title).render(**context)
                content = Template(template_obj.content).render(**context)
                Letter.objects.create(
                    receiver=receiver,
                    type=canvass_type,
                    title=title,
                    content=content,
                    charityEvent=event
                )
            return JsonResponse({'success': True, 'message': '已發送個人催票信'}, status=200)
        else:
            return JsonResponse({'success': True, 'message': '已取消催票信狀態'}, status=200)

    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)