from django.http import JsonResponse, FileResponse
from django.forms.models import model_to_dict
from django.shortcuts import get_object_or_404
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from .models import Book, BookImages
from django.core.exceptions import ValidationError
from django.db.models import Q
from django.core.validators import validate_email
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status


@api_view(["POST"])
@permission_classes([AllowAny])
def login_api(request):
    email = request.data.get("email", "").strip().lower()
    password = request.data.get("password", "")

    if not email or not password:
        return Response(
            {"error": "Email and password are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        validate_email(email)
    except ValidationError:
        return Response(
            {"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(email=email)
        username = user.username
    except User.DoesNotExist:
        return Response(
            {"error": "Invalid email or password"}, status=status.HTTP_401_UNAUTHORIZED
        )

    user = authenticate(request, username=username, password=password)

    if user is None:
        return Response(
            {"error": "Invalid email or password"}, status=status.HTTP_401_UNAUTHORIZED
        )
    if not user.is_active:
        return Response(
            {"error": "Account is deactivated"}, status=status.HTTP_401_UNAUTHORIZED
        )

    token, created = Token.objects.get_or_create(user=user)
    return Response(
        {
            "message": "Login successful",
            "token": token.key,
            "user": {
                "id": user.pk,
                "username": user.username,
                "email": user.email,
            },
        },
        status=status.HTTP_200_OK,
    )


def get_image(request, image_id):
    obj = get_object_or_404(BookImages, pk=image_id)
    return FileResponse(obj.image.open())


def home(request):
    objs = list(Book.objects.all()[:10])
    books = {
        id: model_to_dict(book, fields=["title", "author", "id"])
        for id, book in enumerate(objs)
    }
    return JsonResponse(books)


def catalog(request, search=""):
    books = list(
        Book.objects.order_by("pk")
        .filter(
            Q(description__icontains=search)
            | Q(title__icontains=search)
            | Q(author__icontains=search)
        )
        .all()
    )
    books = {
        id: model_to_dict(book, fields=["title", "author", "id", "description"])
        for id, book in enumerate(books)
    }
    return JsonResponse(books)


def book_page(request, book_id):
    book = get_object_or_404(Book, pk=book_id)
    return JsonResponse(model_to_dict(book))
