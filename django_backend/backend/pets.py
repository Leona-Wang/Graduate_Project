from django.http import JsonResponse
from .models import Pet, PersonalPet

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