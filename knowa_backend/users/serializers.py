# users/serializers.py
from rest_framework import serializers
from .models import User
# Import the default token serializer
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.core.exceptions import ValidationError # For password validation
import re # For password validation

# --- SERIALIZER FOR CUSTOM LOGIN ---
class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Add custom data to the token's payload
        token['username'] = user.username
        token['member_status'] = user.member_status
        token['is_staff'] = user.is_staff

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

# --- ADD THIS NEW SERIALIZER (THIS IS THE FIX) ---
# This serializer is for Admins to view user details
class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        # These are the fields the Admin will see
        fields = [
            'id', 
            'username', 
            'email', 
            'member_status', 
            'date_joined'
        ]