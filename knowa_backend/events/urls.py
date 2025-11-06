# events/urls.py
# maps URLs to the appropriate event class in events/views.py
from django.urls import path
from .views import EventListCreateView, EventDetailView

urlpatterns = [
    # URL for:
    # GET: /api/events/ (List all events)
    # POST: /api/events/ (Create a new event - Admin only)
    path('', EventListCreateView.as_view(), name='event-list-create'),

    # URL for:
    # GET: /api/events/1/ (Get details for event 1)
    # PUT: /api/events/1/ (Update event 1 - Admin only)
    # DELETE: /api/events/1/ (Delete event 1 - Admin only)
    path('<int:pk>/', EventDetailView.as_view(), name='event-detail'),
]