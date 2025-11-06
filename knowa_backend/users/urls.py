# users/urls.py
# connect each url to correct action
from django.urls import path
from .views import (
    RegistrationView, 
    PendingUserListView,
    ApproveUserView,
    RejectUserView,
    InterviewUserView
)
# Import views for login/token creation (we'll add these later)
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer

urlpatterns = [
    # Route for the registration endpoint
    path('register/', RegistrationView.as_view(), name='register'),
    
    path('login/', TokenObtainPairView.as_view(
        serializer_class=MyTokenObtainPairSerializer # <-- TELL DJANGO TO USE IT
    ), name='token_obtain_pair'),

    # --- ADMIN URLs ---
    path('admin/pending/', PendingUserListView.as_view(), name='pending-users'),
    path('admin/approve/<int:pk>/', ApproveUserView.as_view(), name='approve-user'),
    path('admin/reject/<int:pk>/', RejectUserView.as_view(), name='reject-user'),
    
    # --- ADD THIS NEW URL ---
    path('admin/interview/<int:pk>/', InterviewUserView.as_view(), name='interview-user'),
]