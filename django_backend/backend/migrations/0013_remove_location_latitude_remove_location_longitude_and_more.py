# Generated by Django 5.2.3 on 2025-07-20 12:17

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('backend', '0012_alter_officialevent_endtime_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.RemoveField(
            model_name='location',
            name='latitude',
        ),
        migrations.RemoveField(
            model_name='location',
            name='longitude',
        ),
        migrations.AddField(
            model_name='charityevent',
            name='inviteCode',
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='charityevent',
            name='recommendedBy',
            field=models.ManyToManyField(blank=True, related_name='eventRecommendedBy', to=settings.AUTH_USER_MODEL),
        ),
        migrations.AddField(
            model_name='charityinfo',
            name='name',
            field=models.CharField(default='unnamed', max_length=255),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='charityevent',
            name='coOrganizers',
            field=models.ManyToManyField(blank=True, related_name='coEvents', to='backend.charityinfo'),
        ),
        migrations.AlterField(
            model_name='charityevent',
            name='mainOrganizer',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='mainEvents', to='backend.charityinfo'),
        ),
        migrations.AlterField(
            model_name='charityevent',
            name='name',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
        migrations.AlterField(
            model_name='charityevent',
            name='participants',
            field=models.ManyToManyField(blank=True, related_name='eventParticipants', to=settings.AUTH_USER_MODEL),
        ),
    ]
