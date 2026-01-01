# chat/urls.py
from django.urls import path
from .views import (
    ChatRoomListView, 
    ChatRoomDetailView, 
    MessageListView, 
    PinMessageView,
    MarkMessagesReadView,
    MessageInfoView,
    CreateChatRoomView,
    DeleteChatRoomView
)

urlpatterns = [
    path('rooms/', ChatRoomListView.as_view(), name='chat-room-list'),
    path('rooms/<int:pk>/', ChatRoomDetailView.as_view(), name='chat-room-detail'),
    path('rooms/<int:room_id>/messages/', MessageListView.as_view(), name='message-list'),

    path('messages/<int:pk>/pin/', PinMessageView.as_view(), name='message-pin'),
    path('rooms/<int:pk>/read/', MarkMessagesReadView.as_view(), name='mark-read'),
    path('messages/<int:pk>/info/', MessageInfoView.as_view(), name='message-info'),
    path('create/', CreateChatRoomView.as_view(), name='create-chat'),
    path('rooms/<int:pk>/delete/', DeleteChatRoomView.as_view(), name='delete-chat-room'),
]