# users/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserRegistrationSerializer

class RegistrationView(APIView):
    # This view will handle POST requests from the Flutter registration screen
    def post(self, request, format=None):
        serializer = UserRegistrationSerializer(data=request.data)
        
        if serializer.is_valid():
            # If valid, create the user
            user = serializer.save()
            return Response({
                'message': 'Registration successful. Account is pending approval.',
                'username': user.username,
                'status': user.member_status,
            }, status=status.HTTP_201_CREATED)
        
        # If invalid (e.g., passwords don't match, or username taken)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)