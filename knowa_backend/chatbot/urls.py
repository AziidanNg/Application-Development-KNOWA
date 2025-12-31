from django.urls import path
from .views import FAQListView

urlpatterns = [
    # ... your existing chat URLs ...
    path('faqs/', FAQListView.as_view(), name='faq-list'),
]