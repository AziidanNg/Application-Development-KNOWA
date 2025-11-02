# users/urls.py
from django.urls import path
from .views import RegistrationView
# Import views for login/token creation (we'll add these later)
from rest_framework_simplejwt.views import TokenObtainPairView

urlpatterns = [
    # Route for the registration endpoint
    path('register/', RegistrationView.as_view(), name='register'),
    
    # Route for getting a JWT token (user login)
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
]