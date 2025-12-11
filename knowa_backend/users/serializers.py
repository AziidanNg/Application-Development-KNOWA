# users/serializers.py
from rest_framework import serializers
from .models import User
from .models import UserProfile
from .models import Interview
# Import the default token serializer
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.core.exceptions import ValidationError # For password validation
import re # For password validation

# --- SERIALIZER FOR USER PROFILE ---
class UserProfileSerializer(serializers.ModelSerializer):
    # --- NEW: Define fields to build full URLs ---
    resume_url = serializers.SerializerMethodField()
    identification_url = serializers.SerializerMethodField()
    payment_receipt_url = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        # These are the fields from the "Membership Application" form
        # and the new payment receipt field
        fields = [
            'application_type',
            'ic_number', 
            'education', 
            'occupation', 
            'reason_for_joining', 
            'resume', 
            'identification',
            'payment_receipt', # <-- Add this field

            # --- NEW: These are for downloading (read-only) ---
            'resume_url',
            'identification_url',
            'payment_receipt_url',
        ]
        # We add this so a user can't accidentally clear their application
        extra_kwargs = {
            'ic_number': {'required': False},
            'education': {'required': False},
            'occupation': {'required': False},
            'reason_for_joining': {'required': False},
            'resume': {'required': False},
            'identification': {'required': False},
            'payment_receipt': {'required': False},
            'application_type': {'required': False},
        }

    # --- NEW: Helper function to build a full URL ---
    def get_full_url(self, file_field):
        request = self.context.get('request')
        if file_field and hasattr(file_field, 'url'):
            return request.build_absolute_uri(file_field.url)
        return None

    # --- NEW: Functions to use the helper ---
    def get_resume_url(self, obj):
        return self.get_full_url(obj.resume)

    def get_identification_url(self, obj):
        return self.get_full_url(obj.identification)

    def get_payment_receipt_url(self, obj):
        return self.get_full_url(obj.payment_receipt)

# --- SERIALIZER FOR CUSTOM LOGIN ---
class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Add custom data to the token's payload
        token['username'] = user.username
        token['member_status'] = user.member_status
        token['is_staff'] = user.is_staff
        token['first_name'] = user.first_name
        token['phone'] = user.phone
        # Check if the user has a profile and a receipt file
        has_receipt = False
        if hasattr(user, 'profile') and user.profile.payment_receipt:
            has_receipt = True

        token['has_receipt'] = has_receipt
        
        # Check for Rejection Reason
        rejection_reason = ""
        if hasattr(user, 'profile') and user.profile.rejection_reason:
            rejection_reason = user.profile.rejection_reason
        
        token['rejection_reason'] = rejection_reason

        return token

# --- SERIALIZER FOR REGISTRATION ---
class UserRegistrationSerializer(serializers.ModelSerializer):
    password2 = serializers.CharField(style={'input_type': 'password'}, write_only=True)
    first_name = serializers.CharField(required=True) 

    class Meta:
        model = User
        fields = [
            'username', 
            'email', 
            'first_name',
            'phone', 
            'interests',
            'password', 
            'password2'
        ]
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def validate(self, data):
        # 1. Check if passwords match
        if data['password'] != data['password2']:
            raise serializers.ValidationError({"password": "Passwords must match."})

        password = data['password']

        # 2. Check for strong password
        if len(password) < 8:
            raise serializers.ValidationError({"password": "Password must be at least 8 characters."})
        if not re.search(r'[A-Z]', password):
            raise serializers.ValidationError({"password": "Must contain at least one capital letter."})
        if not re.search(r'[a-z]', password):
            raise serializers.ValidationError({"password": "Must contain at least one small letter."})
        if not re.search(r'[0-9]', password):
            raise serializers.ValidationError({"password": "Must contain at least one number."})
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            raise serializers.ValidationError({"password": "Must contain at least one symbol."})
        
        return data

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            phone=validated_data.get('phone', ''),
            interests=validated_data.get('interests', '')
        )
        return user

class InterviewSerializer(serializers.ModelSerializer):
    applicant_name = serializers.CharField(source='applicant.first_name', read_only=True)

    class Meta:
        model = Interview
        fields = ['id', 'applicant', 'applicant_name', 'date_time', 'location', 'meeting_link', 'status']

# --- REPLACE THE OLD AdminUserSerializer ---
class AdminUserSerializer(serializers.ModelSerializer):
    # This "nests" the UserProfile data inside the User data
    profile = UserProfileSerializer(read_only=True)
    interview = InterviewSerializer(read_only=True)
    application_type_display = serializers.CharField(source='profile.get_application_type_display', read_only=True)
    application_date = serializers.DateTimeField(source='profile.application_date', read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 
            'username', 
            'email',
            'first_name', # The "Name" field
            'phone',
            'interests',
            'member_status', 
            'application_date',
            'profile',
            'application_type_display',# <-- This contains all the new application data
            'interview'
        ]