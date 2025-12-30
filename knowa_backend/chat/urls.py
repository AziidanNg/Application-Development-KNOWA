# chat/urls.py
from django.urls import path
from .views import ChatRoomListView, ChatRoomDetailView, MessageListView

urlpatterns = [
    path('rooms/', ChatRoomListView.as_view(), name='chat-room-list'),
    
    # 1. ADD THIS LINE for Group Info to work:
    path('rooms/<int:pk>/', ChatRoomDetailView.as_view(), name='chat-room-detail'),

    path('rooms/<int:room_id>/messages/', MessageListView.as_view(), name='message-list'),
]