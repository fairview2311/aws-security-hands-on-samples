"""書籍のための、意図的に穴を残した顧客管理アプリ。"""

import os
import secrets

import psycopg
import requests
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import FastAPI, Form, Request, UploadFile, File
from fastapi import HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware

from app import db
from app.security import (
    DUMMY_HASH, check_csrf, csrf_token, require_login,
    verify_password,
)
from app.settings import BASE_DIR
from app.storage import (
    MAX_IMAGE_BYTES, import_logo, public_url, put_image,
)


templates = Jinja2Templates(directory=BASE_DIR / "templates")


def render(request, template, status_code=200, **context):
    return templates.TemplateResponse(
        request=request,
        name=template,
        context={
            "csrf_token": csrf_token(request),
            **context,
        },
        status_code=status_code,
    )


def customer_page(request, query="", **context):
    customers = db.list_customers(query)
    for customer in customers:
        customer["card_url"] = public_url(customer["card_key"])
    return render(
        request, "customers.html", customers=customers,
        query=query, logo_url=public_url(db.get_logo_key()),
        **context,
    )


def create_app(session_secret=None):
    app = FastAPI(
        title="みどり文具 顧客管理",
        docs_url=None, redoc_url=None, openapi_url=None,
    )
    secret = session_secret or os.getenv("SESSION_SECRET")
    # 未指定ならプロセスごとに生成。固定値は使わない。
    secret = secret or secrets.token_urlsafe(48)
    if len(secret) < 32:
        raise ValueError("SESSION_SECRET は32文字以上必要です")
    secure = os.getenv("COOKIE_SECURE", "true") != "false"
    app.add_middleware(
        SessionMiddleware,
        secret_key=secret,
        session_cookie="midori_session",
        same_site="lax",
        https_only=secure,
        max_age=3600,
    )
    app.mount(
        "/static", StaticFiles(directory=BASE_DIR / "static"),
        name="static",
    )

    @app.middleware("http")
    async def response_headers(request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
        # 第8章の XSS 演習ができるよう CSP は設定しない。
        return response

    @app.exception_handler(psycopg.Error)
    @app.exception_handler(BotoCoreError)
    @app.exception_handler(ClientError)
    async def backend_error(request, exc):
        return render(
            request, "error.html", status_code=503,
            message="処理できませんでした。接続設定を確認してください。",
        )

    @app.get("/healthz")
    def healthz():
        return {"status": "ok"}

    @app.get("/login", response_class=HTMLResponse)
    def login_form(request: Request):
        return render(request, "login.html")

    @app.post("/login", response_class=HTMLResponse)
    def login(
        request: Request,
        username: str = Form(max_length=100),
        password: str = Form(max_length=1024),
        csrf_token: str = Form(default=""),
    ):
        check_csrf(request, csrf_token)
        user = db.find_user(username)
        password_hash = (
            user["password_hash"] if user else DUMMY_HASH
        )
        valid = verify_password(password_hash, password)
        if not user or not valid:
            return render(
                request, "login.html", status_code=401,
                error="ユーザー名とパスワードを確認してください",
            )
        request.session.clear()
        request.session["user_id"] = user["id"]
        return RedirectResponse("/", status_code=303)

    @app.post("/logout")
    def logout(
        request: Request,
        csrf_token: str = Form(default=""),
    ):
        require_login(request)
        check_csrf(request, csrf_token)
        request.session.clear()
        return RedirectResponse("/login", status_code=303)

    @app.get("/", response_class=HTMLResponse)
    def customers(
        request: Request,
        q: str = Query(default="", max_length=300),
    ):
        require_login(request)
        return customer_page(request, q)

    @app.post("/customers/{customer_id}/memo")
    def save_memo(
        request: Request, customer_id: int,
        memo: str = Form(default="", max_length=5000),
        csrf_token: str = Form(default=""),
    ):
        require_login(request)
        check_csrf(request, csrf_token)
        if not db.save_memo(customer_id, memo):
            raise HTTPException(404, "顧客が見つかりません")
        return RedirectResponse("/", status_code=303)

    @app.post("/customers/{customer_id}/card")
    def upload_card(
        request: Request, customer_id: int,
        image: UploadFile = File(),
        csrf_token: str = Form(default=""),
    ):
        require_login(request)
        check_csrf(request, csrf_token)
        if not db.get_customer(customer_id):
            raise HTTPException(404, "顧客が見つかりません")
        data = image.file.read(MAX_IMAGE_BYTES + 1)
        try:
            key = put_image(data, "cards")
        except ValueError as exc:
            raise HTTPException(400, str(exc)) from exc
        if not db.save_card(customer_id, key):
            raise HTTPException(404, "顧客が見つかりません")
        return RedirectResponse("/", status_code=303)

    @app.post("/logo/import", response_class=HTMLResponse)
    def logo(
        request: Request,
        url: str = Form(max_length=2048),
        csrf_token: str = Form(default=""),
    ):
        require_login(request)
        check_csrf(request, csrf_token)
        try:
            key, preview = import_logo(url)
        except (ValueError, requests.RequestException):
            return customer_page(
                request, error="取り込めませんでした"
            )
        if key:
            db.save_logo(key)
            return RedirectResponse("/", status_code=303)
        return customer_page(
            request, error="取り込めませんでした",
            preview=preview,
        )

    return app


app = create_app()
