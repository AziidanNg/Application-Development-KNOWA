# users/serializers.py
from rest_framework import serializers
from .models import User

# This serializer is for user registration
class UserRegistrationSerializer(serializers.ModelSerializer):
    password2 = serializers.CharField(style={'input_type': 'password'}, write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2']
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def validate(self, data):
        # 1. Ensure passwords match
        if data['password'] != data['password2']:
            raise serializers.ValidationError({"password": "Passwords must match."})
        
        # 2. Add validation for email/username formats here later (optional)

        return data

    def create(self, validated_data):
        # This creates the user in the database
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            # New users default to PENDING status as defined in models.py
        )
        return user