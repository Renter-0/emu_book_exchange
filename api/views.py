from django.http import HttpResponse, JsonResponse, FileResponse
from django.forms.models import model_to_dict
from django.core import serializers
from django.shortcuts import get_object_or_404
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from .models import Book, BookImages
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status


@api_view(["POST"])
@permission_classes([AllowAny])
def login_api(request):
    """
    API endpoint for user login using Django Rest Framework
    """
    email = request.data.get("email", "").strip().lower()
    password = request.data.get("password", "")

    # Validate input
    if not email or not password:
        return Response(
            {"error": "Email and password are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Validate email format
    try:
        validate_email(email)
    except ValidationError:
        return Response(
            {"error": "Invalid email format"}, status=status.HTTP_400_BAD_REQUEST
        )

    # Find user by email
    try:
        user = User.objects.get(email=email)
        username = user.username
    except User.DoesNotExist:
        return Response(
            {"error": "Invalid email or password"}, status=status.HTTP_401_UNAUTHORIZED
        )

    # Authenticate user
    user = authenticate(request, username=username, password=password)

    if user is None:
        return Response(
            {"error": "Invalid email or password"}, status=status.HTTP_401_UNAUTHORIZED
        )
    if not user.is_active:
        return Response(
            {"error": "Account is deactivated"}, status=status.HTTP_401_UNAUTHORIZED
        )

    # Create or get auth token
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
    books = serializers.serialize("json", Book.objects.all()[:10])
    return HttpResponse(books, content_type="application/json")


def catalog(request):
    books = serializers.serialize("json", Book.objects.order_by("pk").all())
    return HttpResponse(books, content_type="application/json")


def book_page(request, book_id):
    book = get_object_or_404(Book, pk=book_id)
    print(model_to_dict(book))
    return JsonResponse(model_to_dict(book))
