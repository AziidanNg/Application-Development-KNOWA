# knowa_server/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings               
from django.conf.urls.static import static     

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/events/', include('events.urls')),
    path('api/donations/', include('donations.urls')),
    path('api/chat/', include('chat.urls')),
    path('api/chatbot/', include('chatbot.urls')),
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)