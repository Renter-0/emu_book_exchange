from django.db import models
from django.contrib.auth.models import User
from django.utils.translation import gettext_lazy as gl


class Book(models.Model):
    class BookCondition(models.TextChoices):
        NEW = "NW", gl("New")
        USED = "UD", gl("Used")
        OLD = "OD", gl("Old")

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=255)
    condition = models.CharField(
        max_length=2, choices=BookCondition, default=BookCondition.USED
    )


class BookImages(models.Model):
    # NOTE: Dunno if I need to allow books without pictures
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    image = models.ImageField()


# NOTE: Maybe add parent field to enable users to respond to other reviews, maybe...
class Review(models.Model):
    class Rating(models.TextChoices):
        NO_RATING = "NR", gl("No Rating provided")
        VERY_BAD = "VB", gl("Very Bad")
        BAD = "BD", gl("Bad")
        NORMAL = "NL", gl("Normal")
        GOOD = "GD", gl("Good")
        VERY_GOOD = "VG", gl("Vergy Good")

    reviewer = models.ForeignKey(User, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    rating = models.CharField(max_length=2, choices=Rating, default=Rating.NO_RATING)
    comment = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)


# NOTE: Situation around account deletion is finicy. Currently if reicever deletes their account then the sender can delete their account
# But for sender to delete their account they need to close the exchange first
class Exchange(models.Model):
    class Status(models.TextChoices):
        COMPLETED = "CD", gl("Completed")
        PENDING = "PG", gl("Pending")

    status = models.CharField(max_length=2, choices=Status, default=Status.PENDING)
    sender = models.ForeignKey(User, on_delete=models.RESTRICT)
    reciever = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="requested_by"
    )
    requested_book = models.ForeignKey(Book, on_delete=models.CASCADE)
    proposed_book = models.ForeignKey(
        Book,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="exchange_with",
    )


class Wishlist(models.Model):
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.SET_NULL, null=True)


# NOTE: I don't think this should be stored in the DB it's better for clients to store locally this information and server acting as a tunnel that connects them
class Message(models.Model):
    sender = models.ForeignKey(
        User, on_delete=models.DO_NOTHING, related_name="send_by"
    )
    reiever = models.ForeignKey(User, on_delete=models.DO_NOTHING)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now=True)
