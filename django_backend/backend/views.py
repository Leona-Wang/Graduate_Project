from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

# Create your views here.
# views.py
@csrf_exempt
def double(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        number = data.get('number', 0)
        result = number * 2
        return JsonResponse({'result': result})
    return JsonResponse({'error': 'Invalid request'}, status=400)