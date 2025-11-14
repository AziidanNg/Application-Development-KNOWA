# donations/models.py
from django.db import models
from django.conf import settings

class Donation(models.Model):
    class DonationStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'

    # Link to the user who donated
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, # Keep the donation record even if user is deleted
        null=True, # Allows for anonymous donations (if we want later)
        related_name='donations'
    )

    # The amount the user *claims* they donated
    amount = models.DecimalField(max_digits=10, decimal_places=2)

    # The uploaded receipt
    receipt = models.FileField(upload_to='donation_receipts/')

    # The admin-verified status
    status = models.CharField(
        max_length=10,
        choices=DonationStatus.choices,
        default=DonationStatus.PENDING # All new donations are PENDING
    )

    # Timestamp
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - RM{self.amount} ({self.status})"