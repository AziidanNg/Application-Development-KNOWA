# users/urls.py
from django.urls import path
from .views import RegistrationView
# Import views for login/token creation (we'll add these later)
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer

urlpatterns = [
    # Route for the registration endpoint
    path('register/', RegistrationView.as_view(), name='register'),
    
    path('login/', TokenObtainPairView.as_view(
        serializer_class=MyTokenObtainPairSerializer # <-- TELL DJANGO TO USE IT
    ), name='token_obtain_pair'),
]