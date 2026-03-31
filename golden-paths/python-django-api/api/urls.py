from django.urls import path
from . import views

urlpatterns = [
    path("items/", views.list_items, name="list-items"),
    path("healthz/", views.health_liveness, name="health-liveness"),
    path("ready/", views.health_readiness, name="health-readiness"),
]
