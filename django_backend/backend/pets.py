from django.http import JsonResponse
from .models import Pet, PersonalPet, PersonalInfo

def getAllPets(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        pets = Pet.objects.all()
        userPetIds = set(PersonalPet.objects.filter(personalInfo__user=user).values_list('pet_id', flat=True)) #「這個 user 擁有的所有寵物 id」的集合，例如 {1, 3, 5}

        result = []
        for pet in pets:
            result.append({
                'id': pet.id,
                'name': pet.name,
                'hasThisPet': pet.id in userPetIds
            })

        return JsonResponse({'success': True, 'pets': result}, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

def petDetail(request, petId):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        if not petId:
            return JsonResponse({'success': False, 'message': '缺少寵物ID'}, status=400)

        pet = Pet.objects.filter(id=petId).first()
        if not pet:
            return JsonResponse({'success': False, 'message': '查無此寵物'}, status=404)

        personalInfo = PersonalInfo.objects.filter(user=user).first()
        if not personalInfo:
            return JsonResponse({'success': False, 'message': '查無玩家資訊'}, status=404)

        # 取得玩家與這隻寵物的 PersonalPet
        personalPet = PersonalPet.objects.filter(personalInfo=personalInfo, pet=pet).first()
        if personalPet and pet.fullPoint:
            point = int((personalPet.currentPoint / pet.fullPoint) * 100)
        else:
            point = 0

        return JsonResponse({
            'success': True,
            'name': pet.name,
            'description': pet.description,
            'point': point,
            'imageUrl': pet.itemImage.url if pet.itemImage else ""
        }, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)