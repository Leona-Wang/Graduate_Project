from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import PersonalInfo
from .models import CharityInfo

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
#B1 抓前端傳回的email值，驗證是否是建立過的個人email
def checkPersonalEmail(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            personalEmail = data.get('personalEmail', '').strip()
            if not personalEmail:
                return JsonResponse({'success': False, 'message': 'No email provided'}, status=400)
            exists = PersonalInfo.objects.filter(user__email=personalEmail).exists()
            return JsonResponse({'exists': exists})
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)
    return JsonResponse({'success': False, 'message': 'Invalid request'}, status=400)

@csrf_exempt
#B2 抓前端傳回的email值，驗證是否是建立過的慈善團體email
def checkCharityEmail(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            groupEmail = data.get('groupEmail', '').strip()
            if not groupEmail:
                return JsonResponse({'success': False, 'message': 'No email provided'}, status=400)
            exists = CharityInfo.objects.filter(organization__email=groupEmail).exists()
            return JsonResponse({'exists': exists})
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)
    return JsonResponse({'success': False, 'message': 'Invalid request'}, status=400)
