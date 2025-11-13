# users/urls.py
from django.urls import path
from .views import (
    RegistrationView, 
    PendingUserListView,
    ApproveUserView,
    RejectUserView,
    InterviewUserView,
    PasswordResetRequestView,
    PasswordResetConfirmView,

    # --- IMPORT THE NEW 2FA VIEWS ---
    LoginRequestTACView,
    LoginVerifyTACView,

    SubmitApplicationView
)
# We no longer need the default TokenObtainPairView here

urlpatterns = [
    # --- Public User URLs ---
    path('register/', RegistrationView.as_view(), name='register'),

    # --- REPLACED LOGIN URL ---
    path('login/', LoginRequestTACView.as_view(), name='2fa-request-tac'),

    # --- NEW 2FA URL ---
    path('verify-2fa/', LoginVerifyTACView.as_view(), name='2fa-verify-tac'),

    # --- Password Reset URLs ---
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),

    # --- NEW: URL for submitting an application ---
    path('apply/', SubmitApplicationView.as_view(), name='submit-application'),

    # --- ADMIN URLs ---
    path('admin/pending/', PendingUserListView.as_view(), name='pending-users'),
    path('admin/approve/<int:pk>/', ApproveUserView.as_view(), name='approve-user'),
    path('admin/reject/<int:pk>/', RejectUserView.as_view(), name='reject-user'),
    path('admin/interview/<int:pk>/', InterviewUserView.as_view(), name='interview-user'),
]