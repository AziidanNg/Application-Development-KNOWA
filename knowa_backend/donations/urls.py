# donations/urls.py
from django.urls import path
from .views import (
    DonationCreateView,
    PendingDonationListView,
    ApproveDonationView,
    RejectDonationView,
    DonationGoalView
)

urlpatterns = [
    # --- Public & User URLs ---
    # POST /api/donations/create/
    path('create/', DonationCreateView.as_view(), name='donation-create'),

    # GET /api/donations/goal/
    path('goal/', DonationGoalView.as_view(), name='donation-goal'),

    # --- Admin URLs ---
    # GET /api/donations/admin/pending/
    path('admin/pending/', PendingDonationListView.as_view(), name='donation-pending-list'),

    # POST /api/donations/admin/approve/<id>/
    path('admin/approve/<int:pk>/', ApproveDonationView.as_view(), name='donation-approve'),

    # POST /api/donations/admin/reject/<id>/
    path('admin/reject/<int:pk>/', RejectDonationView.as_view(), name='donation-reject'),
]