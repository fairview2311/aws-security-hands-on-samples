import re
from copy import deepcopy

import pytest
from fastapi.testclient import TestClient

from app import db
from app.main import create_app
from app.security import hash_password


CUSTOMER = {
    "id": 1,
    "name": "山田 太郎",
    "company": "みどり文具株式会社",
    "email": "test@example.com",
    "phone": "03-0000-0000",
    "address": "東京都千代田区1-1-1",
    "memo": "<strong>訪問予定</strong>",
    "card_key": None,
}


def token(response):
    return re.search(
        r'name="csrf_token" value="([^"]+)"',
        response.text,
    ).group(1)


@pytest.fixture
def client(monkeypatch):
    def forbidden(*args, **kwargs):
        pytest.fail("テストから DB に接続しました")

    monkeypatch.setattr(db, "connect", forbidden)
    monkeypatch.setenv("COOKIE_SECURE", "false")
    with TestClient(create_app("test-secret-" * 5)) as c:
        yield c


@pytest.fixture
def logged_in(client, monkeypatch):
    user = {
        "id": 1,
        "username": "yamada-taro",
        "password_hash": hash_password("test-password"),
    }
    monkeypatch.setattr(db, "find_user", lambda _: user)
    response = client.get("/login")
    response = client.post(
        "/login",
        data={
            "username": "yamada-taro",
            "password": "test-password",
            "csrf_token": token(response),
        },
        follow_redirects=False,
    )
    assert response.status_code == 303
    return client


def mock_page(monkeypatch, customers=None):
    if customers is None:
        customers = [deepcopy(CUSTOMER)]
    monkeypatch.setattr(
        db, "list_customers", lambda q: customers
    )
    monkeypatch.setattr(db, "get_logo_key", lambda: None)


def test_health_without_config_or_db(client, monkeypatch):
    monkeypatch.setenv("MIDORI_CONFIG", "/missing/config.ini")
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_unauthenticated_page_redirects(client):
    response = client.get("/", follow_redirects=False)
    assert response.status_code == 303
    assert response.headers["location"] == "/login"


def test_login_csrf_is_required(client):
    response = client.post(
        "/login",
        data={"username": "yamada-taro", "password": "x"},
    )
    assert response.status_code == 403


def test_wrong_password_has_generic_message(
    client, monkeypatch,
):
    monkeypatch.setattr(db, "find_user", lambda _: None)
    response = client.post(
        "/login",
        data={
            "username": "unknown",
            "password": "wrong",
            "csrf_token": token(client.get("/login")),
        },
    )
    assert response.status_code == 401
    assert "確認してください" in response.text


def test_page_escapes_memo_too(logged_in, monkeypatch):
    customer = deepcopy(CUSTOMER)
    customer["name"] = "<script>name</script>"
    mock_page(monkeypatch, [customer])
    response = logged_in.get(
        "/", params={"q": "<script>q</script>"}
    )
    assert response.status_code == 200
    assert "&lt;strong&gt;訪問予定&lt;/strong&gt;" in response.text
    assert "&lt;script&gt;name&lt;/script&gt;" in response.text
    assert '<script>q</script>' not in response.text


def test_memo_save_and_csrf(logged_in, monkeypatch):
    mock_page(monkeypatch)
    saved = []
    monkeypatch.setattr(
        db, "save_memo",
        lambda cid, memo: saved.append((cid, memo)) or True,
    )
    response = logged_in.post(
        "/customers/1/memo", data={"memo": "訪問済み"}
    )
    assert response.status_code == 403
    assert saved == []
    response = logged_in.post(
        "/customers/1/memo",
        data={
            "memo": "訪問済み",
            "csrf_token": token(logged_in.get("/")),
        },
        follow_redirects=False,
    )
    assert response.status_code == 303
    assert saved == [(1, "訪問済み")]


def test_logo_failure_body_is_escaped(logged_in, monkeypatch):
    from app import main

    mock_page(monkeypatch)
    monkeypatch.setattr(
        main, "import_logo",
        lambda url: (None, "<script>remote</script>"),
    )
    response = logged_in.post(
        "/logo/import",
        data={
            "url": "http://example.invalid/logo",
            "csrf_token": token(logged_in.get("/")),
        },
    )
    assert "取り込めませんでした" in response.text
    escaped = "&lt;script&gt;remote&lt;/script&gt;"
    assert escaped in response.text
    assert "<script>remote</script>" not in response.text


def test_tampered_cookie_loses_login(logged_in, monkeypatch):
    mock_page(monkeypatch)
    logged_in.cookies.clear()
    logged_in.cookies.set("midori_session", "tampered")
    response = logged_in.get("/", follow_redirects=False)
    assert response.status_code == 303


def test_logout_requires_csrf(logged_in, monkeypatch):
    mock_page(monkeypatch)
    csrf = token(logged_in.get("/"))
    assert logged_in.post("/logout").status_code == 403
    response = logged_in.post(
        "/logout", data={"csrf_token": csrf},
        follow_redirects=False,
    )
    assert response.status_code == 303
    response = logged_in.get("/", follow_redirects=False)
    assert response.status_code == 303


def test_non_ascii_csrf_is_rejected(client):
    client.get("/login")
    response = client.post(
        "/login",
        data={
            "username": "yamada-taro", "password": "x",
            "csrf_token": "不正な値",
        },
    )
    assert response.status_code == 403
