from django.core.management.base import BaseCommand
from django.utils import timezone
from backend.models import Letter, Reward, LetterType
from django.template import loader
from django.conf import settings


class Command(BaseCommand):
    help = "寄獎勵"

    def handle(self, *args, **options):

        now = timezone.now().date()

        rewards = Reward.objects.all()

        rewardLetters = []

        letterType = LetterType.objects.filter(type=settings.MAIL_TYPE_REWARD).first()

        for reward in rewards:

            rewardName = reward.item.itemName
            rewardQuantity = reward.quantity
            username = reward.receiver.first_name

            titleTemplate = loader.get_template('RewardLetterTitle.txt')
            title = titleTemplate.render({}).strip()
            contentTemplate = loader.get_template('RewardLetterContent.txt')
            content = contentTemplate.render({
                'userame': username,
                'rewardName': rewardName,
                'rewardQuantity': rewardQuantity
            }).strip()

            rewardLetter = Letter(
                receiver=reward.receiver, date=now, title=title, content=content, reward=reward, letterType=letterType
            )
            rewardLetters.append(rewardLetter)

        Letter.objects.bulk_create(rewardLetters)
