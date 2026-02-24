from django.urls import path
from .views import articles, article


urlpatterns = [
    path("articles/", articles),
    path("articles/<int:pk>/", article),
]
