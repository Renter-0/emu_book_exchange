from django.http import HttpResponse, JsonResponse, FileResponse
from django.forms.models import model_to_dict
from django.core import serializers
from django.shortcuts import get_object_or_404
from .models import Book, BookImages


def get_image(request, image_id):
    obj = get_object_or_404(BookImages, pk=image_id)
    return FileResponse(obj.image.open())


def home(request):
    books = serializers.serialize("json", Book.objects.all()[:10])
    return HttpResponse(books, content_type="application/json")


def catalog(request):
    books = serializers.serialize("json", Book.objects.order_by("pk").all())
    return HttpResponse(books, content_type="application/json")


def book_page(request, book_id):
    book = get_object_or_404(Book, pk=book_id)
    print(model_to_dict(book))
    return JsonResponse(model_to_dict(book))
