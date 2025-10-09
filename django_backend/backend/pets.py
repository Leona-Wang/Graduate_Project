from django.db import transaction
from django.http import JsonResponse
from .models import Pet, PersonalPet, PersonalInfo, ItemBox, Item
from django.conf import settings
import random

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

# 寵物扭蛋機
def gachaPet(request):
    try:
        user = request.user
        if not user or not user.is_authenticated:
            return JsonResponse({'success': False, 'message': '未登入'}, status=401)

        personalInfo = PersonalInfo.objects.filter(user=user).first()
        if not personalInfo:
            return JsonResponse({'success': False, 'message': '查無玩家資訊'}, status=404)

        # 檢查金幣是否足夠
        cashItem = Item.objects.filter(itemType__type=settings.ITEM_CASH).first()
        if not cashItem:
            return JsonResponse({'success': False, 'message': '查無金幣道具'}, status=404)

        itemBox = ItemBox.objects.filter(personalInfo=personalInfo, item=cashItem).first()
        if not itemBox or itemBox.quantity < 5:
            return JsonResponse({'success': False, 'message': '金幣不足'}, status=400)

        # 取得寵物池（假設只有6隻）
        pets = list(Pet.objects.all()[:6])
        if len(pets) < 6:
            return JsonResponse({'success': False, 'message': '寵物池不足6隻'}, status=400)

        # 設定機率（假設每隻寵物機率都一樣）
        weights = [1] * len(pets)
        chosenPet = random.choices(pets, weights=weights, k=1)[0]

        # 檢查玩家是否已擁有這隻寵物
        personalPet = PersonalPet.objects.filter(personalInfo=personalInfo, pet=chosenPet).first()
        newPet = False

        with transaction.atomic():
            if not personalPet:
                # 新增寵物
                PersonalPet.objects.create(personalInfo=personalInfo, pet=chosenPet, currentPoint=1)
                newPet = True
            else:
                # 已擁有該寵物，親密度未滿才加親密度
                if chosenPet.fullPoint and personalPet.currentPoint < chosenPet.fullPoint:
                    addPoint = min(10, chosenPet.fullPoint - personalPet.currentPoint)
                    personalPet.currentPoint += addPoint
                    personalPet.save()
                # 若親密度已滿則不再加親密度

            # 扣金幣
            itemBox.quantity -= 5
            itemBox.save()

        return JsonResponse({
            'success': True,
            'pet': {
                'id': chosenPet.id,
                'name': chosenPet.name,
                'description': chosenPet.description,
                'imageUrl': chosenPet.itemImage.url if chosenPet.itemImage else "",
                'newPet': newPet
            }
        }, status=200)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)