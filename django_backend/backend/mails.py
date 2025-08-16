from django.http import JsonResponse
from .models import Letter

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
            'sender': mail.sender.name if mail.sender else None,
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