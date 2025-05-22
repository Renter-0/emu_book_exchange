from django.contrib import admin
from .models import Book, BookImages, Message, Exchange, Review

admin.site.register([Book, BookImages, Message, Exchange, Review])
