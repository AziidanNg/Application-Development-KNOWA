from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import User, UserProfile, Badge, Interview, Notification

# 1. Define the Inline Profile view
class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Profile'

# 2. Define the Custom User Admin
class CustomUserAdmin(UserAdmin):
    def payment_receipt_link(self, obj):
        # Safely check if profile and receipt exist
        if hasattr(obj, 'profile') and obj.profile.payment_receipt:
            return format_html('<a href="{}" target="_blank">View Receipt</a>', obj.profile.payment_receipt.url)
        return "No receipt uploaded"
    payment_receipt_link.short_description = "Receipt"

    # Add the 'profile' inline to the User page
    inlines = (UserProfileInline,)

    # Update the list display
    list_display = ('username', 'email', 'member_status', 'is_staff', 'payment_receipt_link')
    list_filter = ('member_status', 'is_staff', 'is_active', 'groups')

    fieldsets = UserAdmin.fieldsets + (
        ('Membership', {'fields': ('member_status',)}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Membership', {'fields': ('member_status',)}),
    )

# --- 3. SAFE REGISTRATION LOGIC ---

# First, try to unregister User to prevent "AlreadyRegistered" errors
try:
    admin.site.unregister(User)
except admin.sites.NotRegistered:
    pass

# Now register User with your custom settings
admin.site.register(User, CustomUserAdmin)

# Register other models (wrapped in try-except for safety during hot-reloads)
def safe_register(model):
    try:
        admin.site.register(model)
    except admin.sites.AlreadyRegistered:
        pass

safe_register(UserProfile)
safe_register(Interview)
safe_register(Notification)
safe_register(Badge)  # <--- Your Badge model is now safely registered