import random

from .models import OfficialEvent, OfficialEventParticipant
from django.conf import settings
from django.db.models import Sum


def createCasino(startTime, endTime):
    try:
        officialEvent = OfficialEvent.objects.create(
            type=settings.OFFICAL_EVENT_TYPE_CASINO, startTime=startTime, endTime=endTime
        )
        officialEvent.save()
        return True
    except Exception as e:
        return str(e)


def createBet(user, betEvent, betAmount):
    try:
        OfficialEventParticipant.objects.create(user=user, officialEvent=betEvent, betAmount=betAmount)
        return True
    except Exception as e:
        return str(e)


def updateBet(user, betEvent, updateBetAmount):
    try:
        currentParticipant = OfficialEventParticipant.objects.filter(user=user, officialEvent=betEvent).first()
        currentParticipant.betAmount = updateBetAmount
        currentParticipant.save()
        return True
    except Exception as e:
        return str(e)


def removeBet(user, betEvent):
    try:
        currentParticipant = OfficialEventParticipant.objects.filter(user=user, officialEvent=betEvent).first()
        currentParticipant.delete()
        currentParticipant.save()
        return True
    except Exception as e:
        return str(e)


def getSumOfBet(betEvent):
    amounts = OfficialEventParticipant.objects.filter(officialEvent=betEvent).aggregate(total=Sum('betAmount')
                                                                                       )['totalBetAmount']
    return (amounts or 0)


def getUserWinProbability(user, betEvent):
    totalAmounts = getSumOfBet(betEvent)
    userBetAmount = OfficialEventParticipant.objects.filter(user=user, officialEvent=betEvent).first().betAmount
    probability = round(userBetAmount / totalAmounts, 2)
    return probability


def getWinner(betEvent):

    participants = OfficialEventParticipant.objects.filter(officialEvent=betEvent)

    if not participants.exists():
        return None

    users = []
    weights = []

    for participant in participants:
        users.append(participant.user)
        weights.append(participant.betAmount)

    winner = random.choices(users, weights=weights, k=1)[0]
    return winner


def saveWinner(user, betEvent):
    betEvent.winner = user
    betEvent.save()
    return True
