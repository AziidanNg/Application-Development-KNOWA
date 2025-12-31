from django.db import models

class FAQ(models.Model):
    # Define roles to filter who sees which question
    ROLE_CHOICES = [
        ('all', 'All Users'),
        ('organizer', 'Organizers'),
        ('crew', 'Crew Members'),
        ('participant', 'Participants'),
    ]

    question = models.CharField(max_length=255)
    answer = models.TextField()  # The solution steps
    target_role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='all')
    order = models.IntegerField(default=0)  # To control which question appears first

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"[{self.target_role}] {self.question}"