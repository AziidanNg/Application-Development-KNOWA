# users/serializers.py
from rest_framework import serializers
from .models import User, UserProfile, Interview, Badge, Notification, UserFeedback
# Import the default token serializer
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.core.exceptions import ValidationError 
import re 

# --- SERIALIZER FOR USER PROFILE ---
# 1. BadgeSerializer (Must be first so Profile can use it)
class BadgeSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Badge
        fields = ['id', 'name', 'description', 'image_url', 'criteria_type', 'threshold']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return None

# 2. UserProfileSerializer (Uses BadgeSerializer)
class UserProfileSerializer(serializers.ModelSerializer):
    resume_url = serializers.SerializerMethodField()
    identification_url = serializers.SerializerMethodField()
    payment_receipt_url = serializers.SerializerMethodField()
    status = serializers.CharField(source='user.member_status', read_only=True)
    
    # This includes the list of badges in the profile data
    earned_badges = BadgeSerializer(many=True, read_only=True)

    class Meta:
        model = UserProfile
        fields = [
            'application_type',
            'ic_number', 
            'education', 
            'occupation', 
            'reason_for_joining', 
            'resume', 
            'identification',
            'payment_receipt', 
            'status',
            'resume_url',
            'identification_url',
            'payment_receipt_url',
            'earned_badges', 
            'total_events_joined', 
            'total_donations_made',
        ]
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

    def get_full_url(self, file_field):
        request = self.context.get('request')
        if file_field and hasattr(file_field, 'url'):
            return request.build_absolute_uri(file_field.url)
        return None

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
        token['username'] = user.username
        token['member_status'] = user.member_status
        token['is_staff'] = user.is_staff
        token['first_name'] = user.first_name
        token['phone'] = user.phone
        
        has_receipt = False
        if hasattr(user, 'profile') and user.profile.payment_receipt:
            has_receipt = True
        token['has_receipt'] = has_receipt
        
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
            'username', 'email', 'first_name', 'phone', 'interests',
            'password', 'password2'
        ]
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError({"password": "Passwords must match."})
        
        password = data['password']
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
    applicant_name = serializers.CharField(source='applicant.username', read_only=True)
    
    class Meta:
        model = Interview
        fields = ['id', 'applicant', 'applicant_name', 'date_time', 'status', 'meeting_link', 'report']

class AdminUserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    interview = InterviewSerializer(read_only=True)
    application_type_display = serializers.CharField(source='profile.get_application_type_display', read_only=True)
    application_date = serializers.DateTimeField(source='profile.application_date', read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'phone', 'interests',
            'member_status', 'application_date', 'profile',
            'application_type_display', 'interview'
        ]

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'message', 'is_read', 'created_at', 'notification_type']

# --- UPDATED USER SERIALIZER (THE FIX IS HERE) ---
class UserSerializer(serializers.ModelSerializer):
    badges = serializers.SerializerMethodField()
    total_events = serializers.SerializerMethodField() 
    role = serializers.SerializerMethodField()
    avatar = serializers.SerializerMethodField()
    
    # --- FIX: YOU WERE MISSING THESE LINES ---
    # These tell Django that 'has_receipt' is a function, not a database column
    has_receipt = serializers.SerializerMethodField()
    rejection_reason = serializers.SerializerMethodField()
    # -----------------------------------------

    profile = UserProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 
            'username', 
            'first_name', 
            'email', 
            'role', 
            'avatar', 
            'profile', 
            'badges', 
            'total_events',
            'member_status',      
            'phone',              
            'has_receipt',        # Now this works because we defined it above
            'rejection_reason'    # Now this works because we defined it above
        ]

    def get_role(self, obj):
        if obj.is_superuser or obj.is_staff:
            return 'admin'
        if obj.member_status == 'VOLUNTEER': 
            return 'crew'
        return 'member'

    def get_total_events(self, obj):
        participant_count = 0
        crew_count = 0
        
        if hasattr(obj, 'joined_events_as_participant'):
            participant_count = obj.joined_events_as_participant.count()
        if hasattr(obj, 'joined_events_as_crew'):
            crew_count = obj.joined_events_as_crew.count()
            
        return participant_count + crew_count

    # --- FIX: LOGIC FOR RECEIPT ---
    def get_has_receipt(self, obj):
        # Check if profile exists and if payment_receipt has a file
        if hasattr(obj, 'profile') and obj.profile.payment_receipt:
            return True
        return False

    # --- FIX: LOGIC FOR REJECTION REASON ---
    def get_rejection_reason(self, obj):
        if hasattr(obj, 'profile') and obj.profile.rejection_reason:
            return obj.profile.rejection_reason
        return ""

    def get_badges(self, obj):
        badges_data = []
        total_events = self.get_total_events(obj)
        
        total_donations = 0
        if hasattr(obj, 'profile') and hasattr(obj.profile, 'total_donations_made'):
            total_donations = obj.profile.total_donations_made

        event_badges_rules = [
            (1, "NEWCOMER"),      
            (5, "MEMBER"),        
            (10, "ENTHUSIAST"),   
            (20, "VETERAN"),
            (50, "LEGEND"),
        ]

        donation_badges_rules = [
            (1, "SUPPORTER"),
            (5, "CONTRIBUTOR"),
            (10, "PARTNER"),
            (20, "PATRON"),
            (50, "PHILANTHROPIST"),
        ]

        def try_add_badge(name):
            from users.models import Badge 
            try:
                real_badge = Badge.objects.get(name=name)
                image_url = None
                if real_badge.image:
                    request = self.context.get('request')
                    if request:
                        image_url = request.build_absolute_uri(real_badge.image.url)
                    else:
                        image_url = real_badge.image.url
                
                badges_data.append({
                    "name": real_badge.name,
                    "description": real_badge.description,
                    "image_url": image_url,
                    "icon": "star"
                })
            except Badge.DoesNotExist:
                pass
            except Exception as e:
                # print(f"Error adding badge: {e}")
                pass

        for threshold, badge_name in event_badges_rules:
            if total_events >= threshold:
                try_add_badge(badge_name)

        for threshold, badge_name in donation_badges_rules:
            if total_donations >= threshold:
                try_add_badge(badge_name)

        return badges_data

    def get_avatar(self, obj):
        try:
            if hasattr(obj, 'profile') and obj.profile.avatar:
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(obj.profile.avatar.url)
                return obj.profile.avatar.url
        except Exception:
            pass
        return None

class UserFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserFeedback
        fields = ['category', 'message']