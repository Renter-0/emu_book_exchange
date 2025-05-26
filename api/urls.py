from django.urls import path
from . import views

urlpatterns = [
    path("", views.home),
    path("catalog/", views.catalog),
    path("catalog/<str:search>", views.catalog),
    path("book/<int:book_id>", views.book_page),
    path("image/<int:image_id>", views.get_image),
    path("log_in/", views.login_api),
]
