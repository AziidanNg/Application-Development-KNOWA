from django.contrib import admin
from .models import FAQ

@admin.register(FAQ)
class FAQAdmin(admin.ModelAdmin):
    list_display = ('question', 'target_role', 'order')
    list_filter = ('target_role',)
    search_fields = ('question', 'answer')