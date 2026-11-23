"""
Multi-Agent RAG SaaS API — application entry point.

Creates the FastAPI app, registers middleware, exception handlers, and routers.
"""

import logging
import os

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.exceptions import AppException, RateLimitError
from app.core.middleware import RequestLoggingMiddleware
from app.core.rate_limit import RateLimitMiddleware

from app.features.auth.router import router as auth_router
from app.features.users.router import router as user_router
from app.features.chat.router import router as chat_router
from app.features.public.router import router as public_router
from app.features.billing.router import router as billing_router

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Multi-Agent RAG SaaS API",
    description="Multi-tenant chatbot platform with RAG-powered responses",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("ragsaas")

# ---------------------------------------------------------------------------
# Middleware (order matters — outermost first)
# ---------------------------------------------------------------------------

# CORS — restrict in production, allow-all only behind a flag
ALLOWED_ORIGINS = os.getenv("CORS_ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(RateLimitMiddleware, max_requests=60, window_seconds=60)
app.add_middleware(RequestLoggingMiddleware)

# ---------------------------------------------------------------------------
# Exception handlers
# ---------------------------------------------------------------------------

@app.exception_handler(AppException)
async def app_exception_handler(_request: Request, exc: AppException):
    headers = {}
    if isinstance(exc, RateLimitError):
        headers["Retry-After"] = str(exc.retry_after)
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.message}, headers=headers)


@app.exception_handler(ValueError)
async def value_error_handler(_request: Request, exc: ValueError):
    return JSONResponse(status_code=400, content={"detail": str(exc)})


# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------

app.include_router(auth_router)
app.include_router(user_router)
app.include_router(chat_router)
app.include_router(public_router)
app.include_router(billing_router)

# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------

@app.get("/")
async def root():
    return {
        "message": "Multi-Agent RAG SaaS API",
        "status": "healthy",
        "version": "2.0.0",
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

main = app

if __name__ == "__main__":
    import uvicorn

    logger.info("Starting Multi-Agent RAG SaaS API")
    uvicorn.run("app.main:app", port=8081, reload=True)
