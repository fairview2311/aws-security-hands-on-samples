"""名刺と会社ロゴを S3 に保存する。"""

from urllib.parse import urlsplit
from uuid import uuid4

import boto3
from botocore.config import Config
import requests

from app.settings import read_config


MAX_IMAGE_BYTES = 2 * 1024 * 1024
IMAGE_URL_SECONDS = 300


def image_type(data):
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png", "png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg", "jpg"
    if data.startswith((b"GIF87a", b"GIF89a")):
        return "image/gif", "gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp", "webp"
    raise ValueError("PNG・JPEG・GIF・WebP を選んでください")


def put_image(data, prefix):
    if not data or len(data) > MAX_IMAGE_BYTES:
        raise ValueError("画像は 2 MiB 以下にしてください")
    content_type, extension = image_type(data)
    config = read_config()["aws"]
    key = f"{prefix}/{uuid4().hex}.{extension}"
    client = boto3.client("s3", region_name=config["region"])
    client.put_object(
        Bucket=config["bucket"],
        Key=key,
        Body=data,
        ContentType=content_type,
        ContentDisposition="inline",
    )
    return key


def image_url(key):
    if not key:
        return None
    config = read_config()["aws"]
    region = config["region"]
    client = boto3.client(
        "s3",
        region_name=region,
        endpoint_url=f"https://s3.{region}.amazonaws.com",
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": "virtual"},
        ),
    )
    # 5分だけ読める URL を作る。期限を過ぎると読めなくなる
    return client.generate_presigned_url(
        "get_object",
        Params={"Bucket": config["bucket"], "Key": key},
        ExpiresIn=IMAGE_URL_SECONDS,
    )


def import_logo(url):
    if urlsplit(url).scheme not in {"http", "https"}:
        raise ValueError("http または https の URL を入力してください")
    # 演習用の脆弱性（第7章で直す）。本番で使わない
    response = requests.get(url, timeout=(3, 5), stream=True)
    with response:
        # 非画像の応答も表示できるよう、HTTP エラーを許容する。
        chunks = bytearray()
        for chunk in response.iter_content(chunk_size=16384):
            chunks.extend(chunk)
            if len(chunks) > MAX_IMAGE_BYTES:
                raise ValueError("取り込むデータが大きすぎます")
        data = bytes(chunks)
        content_type = response.headers.get("Content-Type", "")
        if response.ok and content_type.startswith("image/"):
            try:
                image_type(data)
            except ValueError:
                pass
            else:
                return put_image(data, "logos"), None
        encoding = response.encoding or "utf-8"
        try:
            preview = data.decode(encoding, errors="replace")
        except LookupError:
            preview = data.decode("utf-8", errors="replace")
        return None, preview[:2000]
