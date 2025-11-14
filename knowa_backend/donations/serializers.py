# donations/serializers.py
from rest_framework import serializers
from .models import Donation
from users.models import User

# Serializer for a user to SUBMIT a new donation
class DonationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Donation
        fields = ['amount', 'receipt'] # These are the only fields the user needs to send
        extra_kwargs = {
            'receipt': {'required': True}, # Make the receipt mandatory
        }

# Serializer for an ADMIN to VIEW a donation
class DonationAdminSerializer(serializers.ModelSerializer):
    # Show the user's name, not just their ID
    username = serializers.ReadOnlyField(source='user.username')

    # Build the full, clickable URL for the receipt
    receipt_url = serializers.SerializerMethodField()

    class Meta:
        model = Donation
        fields = [
            'id',
            'user',
            'username',
            'amount',
            'receipt_url', # Send the URL
            'status',
            'submitted_at'
        ]

    def get_receipt_url(self, obj):
        request = self.context.get('request')
        if obj.receipt and hasattr(obj.receipt, 'url'):
            return request.build_absolute_uri(obj.receipt.url)
        return None