"""パスワードとフォームの保護。"""

import secrets

from argon2 import PasswordHasher
from argon2.exceptions import (
    VerificationError, InvalidHashError,
)
from fastapi import HTTPException


hasher = PasswordHasher()
# 存在しないユーザーでもハッシュの照合を行う。
DUMMY_HASH = hasher.hash(secrets.token_urlsafe(32))


def hash_password(password):
    return hasher.hash(password)


def verify_password(password_hash, password):
    try:
        return hasher.verify(password_hash, password)
    except (VerificationError, InvalidHashError):
        return False


def csrf_token(request):
    if "csrf" not in request.session:
        request.session["csrf"] = secrets.token_urlsafe(32)
    return request.session["csrf"]


def check_csrf(request, submitted):
    expected = request.session.get("csrf")
    if not expected or not secrets.compare_digest(
        expected.encode(), (submitted or "").encode()
    ):
        raise HTTPException(403, "画面を開き直してください")


def require_login(request):
    if "user_id" not in request.session:
        raise HTTPException(
            303, headers={"Location": "/login"}
        )
