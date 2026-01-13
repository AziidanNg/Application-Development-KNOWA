import google.generativeai as genai
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Q
from django.conf import settings
from .models import FAQ
from .serializers import FAQSerializer

# --- 1. CONFIGURE GEMINI (Using the key from Railway/settings.py) ---
try:
    genai.configure(api_key=settings.GEMINI_API_KEY)
except Exception as e:
    print(f"Warning: Gemini API Key not configured properly: {e}")

# --- 2. YOUR EXISTING FAQ LIST VIEW (Keep this for the button) ---
class FAQListView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = FAQSerializer

    def get_queryset(self):
        user = self.request.user
        filters = Q(target_role='all')

        if user.is_authenticated:
            if user.is_staff or user.is_superuser:
                filters |= Q(target_role='organizer')
            else:
                filters |= Q(target_role='participant')
        
        return FAQ.objects.filter(filters).distinct()

# --- 3. NEW: CHATBOT API VIEW (Handles the actual chatting) ---
class ChatbotAPIView(APIView):
    permission_classes = [permissions.AllowAny] # Allow guests to ask questions

    def post(self, request):
        # 1. Get the user's message
        user_query = request.data.get('message') or request.data.get('query')
        
        if not user_query:
            return Response({'error': 'No message provided'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. CHECK DATABASE FAQ FIRST (Case-insensitive Search)
        # Using 'icontains' helps match "what is knowa" with "What is KNOWA?"
        faq_match = FAQ.objects.filter(question__icontains=user_query).first()
        
        if faq_match:
            return Response({
                'response': faq_match.answer,
                'source': 'database'
            })

        # 3. IF NO FAQ MATCH, ASK GEMINI (With Context Injection)
        try:
            model = genai.GenerativeModel('gemini-pro')
            
            # --- THIS BLOCK TEACHES GEMINI WHO IT IS ---
            system_instruction = """
            SYSTEM CONTEXT:
            You are the friendly AI Assistant for 'KNOWA'.
            
            WHAT IS KNOWA?
            - KNOWA is a digital platform built for the 'Persatuan Ilmiah Pulau Pinang' NGO.
            - It simplifies management for both users (volunteers/donors) and the organization.
            - Key features: Event registration, Membership application, Donations, and Volunteer management.
            
            YOUR INSTRUCTIONS:
            - Answer the user's question briefly (max 3 sentences).
            - If asked 'What is Knowa?', use the definition above.
            - If you genuinely do not know the answer, politely ask the user to contact 'admin@knowa.org'.
            
            USER QUESTION:
            """
            
            # Combine instruction + user question
            final_prompt = f"{system_instruction} {user_query}"
            
            response = model.generate_content(final_prompt)
            
            return Response({
                'response': response.text,
                'source': 'ai'
            })
            
        except Exception as e:
            print(f"Gemini Error: {e}")
            return Response(
                {'response': "I'm having trouble connecting to the server. Please try again later."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )