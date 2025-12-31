from rest_framework import generics, permissions
from django.db.models import Q
from .models import FAQ
from .serializers import FAQSerializer

class FAQListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FAQSerializer

    def get_queryset(self):
        user = self.request.user
        
        # 1. Base rule: Show questions meant for everyone
        filters = Q(target_role='all')

        # 2. Add specific roles based on user status
        if user.is_staff or user.is_superuser:
            filters |= Q(target_role='organizer')
        
        # NOTE: If you have a specific 'is_crew' field or group, add it here:
        # if user.groups.filter(name='Crew').exists():
        #     filters |= Q(target_role='crew')
        
        # If not staff (and assuming not crew), you are a participant
        if not user.is_staff:
            filters |= Q(target_role='participant')

        return FAQ.objects.filter(filters).distinct()