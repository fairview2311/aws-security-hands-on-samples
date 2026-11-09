from types import SimpleNamespace

import pytest

from app import storage


class RemoteResponse:
    ok = True
    encoding = "utf-8"

    def __init__(self, body, content_type="text/plain"):
        self.body = body
        self.headers = {"Content-Type": content_type}

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def iter_content(self, chunk_size):
        yield self.body


def test_nonimage_preview_is_limited_to_2000_chars(monkeypatch):
    response = RemoteResponse(("あ" * 2500).encode())
    monkeypatch.setattr(
        storage.requests, "get", lambda *a, **kw: response
    )
    key, preview = storage.import_logo(
        "http://example.invalid/"
    )
    assert key is None
    assert preview == "あ" * 2000


def test_non_http_url_is_rejected():
    with pytest.raises(ValueError):
        storage.import_logo("file:///etc/passwd")


def test_oversized_remote_image_is_rejected(monkeypatch):
    response = RemoteResponse(
        b"x" * (storage.MAX_IMAGE_BYTES + 1), "image/png"
    )
    monkeypatch.setattr(
        storage.requests, "get", lambda *a, **kw: response
    )
    with pytest.raises(ValueError, match="大きすぎ"):
        storage.import_logo("http://example.invalid/")


def test_svg_upload_is_rejected_without_s3():
    with pytest.raises(ValueError, match="PNG"):
        storage.put_image(b"<svg></svg>", "cards")


def test_image_url_is_signed_and_expires(monkeypatch):
    monkeypatch.delenv("AWS_PROFILE", raising=False)
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setattr(storage, "read_config", lambda: {
        "aws": {"bucket": "example", "region": "ap-northeast-1"}
    })
    url = storage.image_url("cards/a b.png")
    assert url.startswith(
        "https://example.s3.ap-northeast-1.amazonaws.com/"
        "cards/a%20b.png?X-Amz-Algorithm=AWS4-HMAC-SHA256"
    )
    assert "X-Amz-Expires=300" in url
    assert storage.image_url(None) is None


def test_image_upload_uses_generated_key_and_correct_type(
    monkeypatch,
):
    sent = []
    monkeypatch.setattr(storage, "read_config", lambda: {
        "aws": {"bucket": "example", "region": "ap-northeast-1"}
    })
    monkeypatch.setattr(
        storage.boto3, "client",
        lambda *a, **kw: SimpleNamespace(
            put_object=lambda **obj: sent.append(obj)
        ),
    )
    data = b"\x89PNG\r\n\x1a\n" + b"test-image"
    key = storage.put_image(data, "cards")
    assert key.startswith("cards/") and key.endswith(".png")
    assert sent == [{
        "Bucket": "example", "Key": key, "Body": data,
        "ContentType": "image/png",
        "ContentDisposition": "inline",
    }]


def test_remote_image_is_saved(monkeypatch):
    data = b"\x89PNG\r\n\x1a\n" + b"test-image"
    response = RemoteResponse(data, "image/png")
    monkeypatch.setattr(
        storage.requests, "get", lambda *a, **kw: response
    )
    saved = []

    def save(body, prefix):
        saved.append((body, prefix))
        return "logos/test.png"

    monkeypatch.setattr(storage, "put_image", save)
    assert storage.import_logo("https://example.invalid/") == (
        "logos/test.png", None
    )
    assert saved == [(data, "logos")]
