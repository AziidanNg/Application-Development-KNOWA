# users/urls.py
from django.urls import path
from .views import (
    RegistrationView, 
    PendingUserListView,
    ApproveForMembershipView,
    ApproveAsVolunteerView,
    RejectUserView,
    InterviewUserView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    LoginRequestTACView,
    LoginVerifyTACView,
    SubmitApplicationView,
    UploadReceiptView,
    PendingPaymentListView,
    ConfirmPaymentView,
    AdminDashboardStatsView,
    RejectPaymentView,
    MyScheduleView,
    StaffListView,
    NotificationListView,
    MarkNotificationReadView
)

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

    # --- 2. ADD NEW URL for uploading a receipt ---
    path('upload-receipt/', UploadReceiptView.as_view(), name='upload-receipt'),

    # --- ADMIN URLs ---
    path('admin/stats/', AdminDashboardStatsView.as_view(), name='admin-stats'),
    path('admin/pending/', PendingUserListView.as_view(), name='pending-users'),
    path('admin/approve-member/<int:pk>/', ApproveForMembershipView.as_view(), name='approve-member'),
    path('admin/approve-volunteer/<int:pk>/', ApproveAsVolunteerView.as_view(), name='approve-volunteer'),
    path('admin/reject/<int:pk>/', RejectUserView.as_view(), name='reject-user'),
    path('admin/interview/<int:pk>/', InterviewUserView.as_view(), name='interview-user'),

    # --- 2. ADD NEW URLs for payment confirmation ---
    path('admin/pending-payments/', PendingPaymentListView.as_view(), name='pending-payments'),
    path('admin/confirm-payment/<int:pk>/', ConfirmPaymentView.as_view(), name='confirm-payment'),
    path('admin/reject-payment/<int:pk>/', RejectPaymentView.as_view(), name='reject-payment'),
    path('admin/staff-list/', StaffListView.as_view(), name='staff-list'),

    path('my-schedule/', MyScheduleView.as_view(), name='my-schedule'),
    path('notifications/', NotificationListView.as_view(), name='notifications'),
    path('notifications/<int:pk>/read/', MarkNotificationReadView.as_view(), name='read-notification')
]