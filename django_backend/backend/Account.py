import json
from .models import PersonalInfo, CharityInfo
from django.http import JsonResponse


def validateEmail(request):

    try:
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

    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)
