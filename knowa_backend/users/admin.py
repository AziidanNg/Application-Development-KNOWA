# users/admin.py
# admins to view, filter and edit users in the admin panel

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

# This customizes the admin page
class CustomUserAdmin(UserAdmin):
    # Add our new field to the list display
    list_display = ('username', 'email', 'member_status', 'is_staff')
    
    # Add a filter on the side
    list_filter = ('member_status', 'is_staff', 'is_active', 'groups')

    # Add it to the "edit" page fields
    fieldsets = UserAdmin.fieldsets + (
        ('Membership', {'fields': ('member_status',)}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Membership', {'fields': ('member_status',)}),
    )

# Register your model
admin.site.register(User, CustomUserAdmin)