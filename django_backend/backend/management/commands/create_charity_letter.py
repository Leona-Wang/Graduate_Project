from django.core.management.base import BaseCommand
from django.utils import timezone
from backend.models import EventParticipant, Letter, CharityEvent, LetterType
from django.template import loader
from django.conf import settings


class Command(BaseCommand):
    help = "活動三天前寄信(有興趣的寄推薦，參加的寄通知)，之後自動化每天跑一次"

    def handle(self, *args, **options):

        now = timezone.now().date()
        charityEvents = CharityEvent.objects.all()

        promoteLetters = []
        joinLetters = []

        letterType = LetterType.objects.filter(type=settings.MAIL_TYPE_EVENT).first()

        for charityEvent in charityEvents:
            #預設3天前宣傳
            promoteDay = 3
            daysDiff = (charityEvent.startTime.date() - now).days

            if daysDiff <= promoteDay:

                saves = EventParticipant.objects.filter(charityEvent=charityEvent, joinType=settings.CHARITY_EVENT_SAVE)
                joins = EventParticipant.objects.filter(charityEvent=charityEvent, joinType=settings.CHARITY_EVENT_JOIN)

                charityName = charityEvent.mainOrganizer.name
                eventStartTime = charityEvent.startTime.strftime("%Y年%m月%d日")
                charityEventName = charityEvent.name

                for save in saves:
                    titleTemplate = loader.get_template('PromoteLetterTitle.txt')
                    title = titleTemplate.render({}).strip()
                    contentTemplate = loader.get_template('PromoteLetterContent.txt')
                    content = contentTemplate.render({
                        'userame': save.personalUser.first_name,
                        'charityName': charityName,
                        'eventStartTime': eventStartTime,
                        'charityEventName': charityEventName,
                    }).strip()

                    promoteLetter = Letter(
                        receiver=save.personalUser,
                        date=now,
                        title=title,
                        content=content,
                        charityEvent=charityEvent,
                        letterType=letterType
                    )
                    promoteLetters.append(promoteLetter)

                for join in joins:
                    titleTemplate = loader.get_template('InformLetterTitle.txt')
                    title = titleTemplate.render({}).strip()
                    contentTemplate = loader.get_template('InformLetterContent.txt')
                    content = contentTemplate.render({
                        'userame': join.personalUser.first_name,
                        'charityName': charityName,
                        'eventStartTime': eventStartTime,
                        'charityEventName': charityEventName,
                    }).strip()

                    joinLetter = Letter(
                        receiver=join.personalUser,
                        date=now,
                        title=title,
                        content=content,
                        charityEvent=charityEvent,
                        letterType=letterType
                    )
                    joinLetters.append(joinLetter)

        Letter.objects.bulk_create(promoteLetters)
        Letter.objects.bulk_create(joinLetters)
