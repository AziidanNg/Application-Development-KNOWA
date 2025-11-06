# events/admin.py
# This file customizes how events appear in the Django admin panel
from django.contrib import admin
from .models import Event

class EventAdmin(admin.ModelAdmin):
    # Controls the columns you see in the event list
    list_display = ('title', 'location', 'start_time', 'organizer')
    list_filter = ('start_time', 'location')
    search_fields = ('title', 'description')

admin.site.register(Event, EventAdmin)