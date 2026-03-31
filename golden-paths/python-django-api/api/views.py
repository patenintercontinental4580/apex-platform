from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)


@api_view(["GET"])
@permission_classes([AllowAny])
def health_liveness(request):
    """Liveness probe endpoint — returns 200 if the process is running."""
    return Response({"status": "alive"}, status=status.HTTP_200_OK)


@api_view(["GET"])
@permission_classes([AllowAny])
def health_readiness(request):
    """Readiness probe endpoint — returns 200 if the service is ready to accept traffic."""
    return Response({"status": "ready"}, status=status.HTTP_200_OK)


@api_view(["GET"])
def list_items(request):
    """Example list endpoint."""
    logger.info("Listing items for user %s", request.user)
    items = [
        {"id": 1, "name": "Item One", "description": "The first item."},
        {"id": 2, "name": "Item Two", "description": "The second item."},
    ]
    return Response(items)
