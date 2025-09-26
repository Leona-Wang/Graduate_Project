import random

from .models import OfficialEvent, OfficialEventParticipant, PersonalInfo, Item, ItemBox, Reward
from django.conf import settings
from django.db.models import Sum


def createCasino(startTime, endTime):
    try:
        officialEvent = OfficialEvent.objects.create(
            type=settings.OFFICIAL_EVENT_TYPE_CASINO, startTime=startTime, endTime=endTime
        )
        officialEvent.save()
        return True
    except Exception as e:
        return str(e)


def getUserBetAmount(user):

    betEvent = OfficialEvent.objects.filter(type=settings.OFFICIAL_EVENT_TYPE_CASINO).last()
    participant = OfficialEventParticipant.objects.filter(user=user, officialEvent=betEvent).first()
    if participant:
        betAmount = participant.betAmount
    else:
        betAmount = 0
    return betAmount


def getTotalBetAmount():
    betEvent = OfficialEvent.objects.filter(type=settings.OFFICIAL_EVENT_TYPE_CASINO).last()
    totalBetAmount = OfficialEventParticipant.objects.filter(officialEvent=betEvent).aggregate(total=Sum('betAmount')
                                                                                              )['total'] or 0
    return totalBetAmount


def createOrUpdateBet(user, betEvent, betAmount):
    try:
        personalInfo = PersonalInfo.objects.filter(user=user).first()

        prize = Item.objects.filter(name=settings.ITEM_CASH).first()

        coinAmount = ItemBox.objects.filter(personalInfo=personalInfo, item=prize).first().quantity

        if betAmount > coinAmount:
            return False

        currentParticipant, created = OfficialEventParticipant.objects.get_or_create(
            user=user, officialEvent=betEvent, defaults={'betAmount': betAmount}
        )

        if not created:
            currentParticipant.betAmount = betAmount
            currentParticipant.save()

        return True
    except Exception as e:
        return str(e)


def deductCoin(user, betAmount):

    personalInfo = PersonalInfo.objects.filter(user=user).first()

    prize = Item.objects.filter(name=settings.ITEM_CASH).first()

    item = ItemBox.objects.filter(personalInfo=personalInfo, item=prize).first()
    item.quantity = item.quantity - betAmount
    item.save()


def getWinner(betEvent):

    participants = OfficialEventParticipant.objects.filter(officialEvent=betEvent)

    if not participants.exists():
        return None

    users = []
    weights = []

    for participant in participants:
        users.append(participant.user)
        weights.append(participant.betAmount)
        deductCoin(participant.user, participant.betAmount)

    winner = random.choices(users, weights=weights, k=1)[0]
    return winner


def saveWinner(user, betEvent):
    betEvent.winner = user
    betEvent.save()

    totalBetAmount = getTotalBetAmount()
    #0.5=>拿到總價的0.5
    quantity = totalBetAmount * 0.5
    prize = Item.objects.filter(name=settings.ITEM_CASH).first()
    receiver = user
    reward = Reward.objects.create(prize=prize, receiver=receiver, quantity=quantity)
    reward.save()
    return True
