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
    
