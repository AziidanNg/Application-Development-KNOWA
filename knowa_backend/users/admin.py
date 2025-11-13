# users/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import User, UserProfile # Import UserProfile

# This "inlines" the UserProfile model inside the User admin page
class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Profile'

class CustomUserAdmin(UserAdmin):
    # --- NEW: Add a function to show a clickable link to the receipt ---
    def payment_receipt_link(self, obj):
        if obj.profile.payment_receipt:
            return format_html('<a href="{}" target="_blank">View Receipt</a>', obj.profile.payment_receipt.url)
        return "No receipt uploaded"
    payment_receipt_link.short_description = "Receipt"

    # Add the 'profile' inline to the User page
    inlines = (UserProfileInline,)

    # Update the list display to show status and the new receipt link
    list_display = ('username', 'email', 'member_status', 'is_staff', 'payment_receipt_link')
    list_filter = ('member_status', 'is_staff', 'is_active', 'groups')

    # ... (your fieldsets and add_fieldsets are fine) ...
    fieldsets = UserAdmin.fieldsets + (
        ('Membership', {'fields': ('member_status',)}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Membership', {'fields': ('member_status',)}),
    )

# Re-register your User model with these new settings
admin.site.register(User, CustomUserAdmin)