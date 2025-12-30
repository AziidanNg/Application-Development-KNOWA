# chat/urls.py
from django.urls import path
from .views import ChatRoomListView, MessageListView

urlpatterns = [
    path('rooms/', ChatRoomListView.as_view(), name='chat-room-list'),
    path('rooms/<int:room_id>/messages/', MessageListView.as_view(), name='message-list'),
]