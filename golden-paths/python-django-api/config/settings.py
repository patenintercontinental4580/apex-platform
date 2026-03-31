"""
Django settings for the Apex Platform Python Django API golden path.

Secrets are loaded from Azure Key Vault at startup using DefaultAzureCredential.
Configuration is environment-driven via environment variables.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ── Azure Key Vault Integration ───────────────────────────────────────────────
KEY_VAULT_URI = os.environ.get("KEY_VAULT_URI", "")

_kv_secrets: dict[str, str] = {}

if KEY_VAULT_URI:
    try:
        from azure.identity import DefaultAzureCredential
        from azure.keyvault.secrets import SecretClient

        _credential = DefaultAzureCredential()
        _kv_client = SecretClient(vault_url=KEY_VAULT_URI, credential=_credential)

        def _get_secret(name: str, default: str = "") -> str:
            """Fetches a secret from Azure Key Vault with a fallback default."""
            if name in _kv_secrets:
                return _kv_secrets[name]
            try:
                secret = _kv_client.get_secret(name)
                _kv_secrets[name] = secret.value or default
                return _kv_secrets[name]
            except Exception:
                return default

    except Exception as exc:
        import warnings

        warnings.warn(f"Could not initialise Azure Key Vault client: {exc}", stacklevel=1)

        def _get_secret(name: str, default: str = "") -> str:  # type: ignore[misc]
            return os.environ.get(name.upper().replace("-", "_"), default)

else:

    def _get_secret(name: str, default: str = "") -> str:  # type: ignore[misc]
        return os.environ.get(name.upper().replace("-", "_"), default)


# ── Security ──────────────────────────────────────────────────────────────────
SECRET_KEY = _get_secret(
    "django-secret-key",
    os.environ.get("DJANGO_SECRET_KEY", "insecure-local-dev-key"),
)
DEBUG = os.environ.get("DJANGO_DEBUG", "False").lower() == "true"
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")

# ── Application Definition ────────────────────────────────────────────────────
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "health_check",
    "health_check.db",
    "health_check.cache",
    "health_check.storage",
    "api",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "opencensus.ext.django.middleware.OpencensusMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# ── Database ──────────────────────────────────────────────────────────────────
_db_url = _get_secret("database-url", os.environ.get("DATABASE_URL", ""))

if _db_url:
    import urllib.parse

    _parsed = urllib.parse.urlparse(_db_url)
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": _parsed.path.lstrip("/"),
            "USER": _parsed.username,
            "PASSWORD": _parsed.password,
            "HOST": _parsed.hostname,
            "PORT": _parsed.port or 5432,
            "OPTIONS": {"sslmode": "require"},
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

# ── OpenCensus / Azure Monitor Tracing ────────────────────────────────────────
OPENCENSUS = {
    "TRACE": {
        "SAMPLER": "opencensus.trace.samplers.ProbabilitySampler(rate=1)",
        "EXPORTER": (
            "opencensus.ext.azure.trace_exporter.AzureExporter("
            f"connection_string='{os.environ.get('APPLICATIONINSIGHTS_CONNECTION_STRING', '')}'"
            ")"
        ),
        "EXCLUDELIST_PATHS": ["/healthz", "/ready"],
    }
}

# ── REST Framework ────────────────────────────────────────────────────────────
REST_FRAMEWORK = {
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.SessionAuthentication",
    ],
}

# ── Internationalisation ──────────────────────────────────────────────────────
LANGUAGE_CODE = "en-gb"
TIME_ZONE = "Europe/London"
USE_I18N = True
USE_TZ = True

# ── Static Files ──────────────────────────────────────────────────────────────
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
