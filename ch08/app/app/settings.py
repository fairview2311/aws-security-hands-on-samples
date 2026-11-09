"""設定と、Secrets Manager からのパスワードの取得。"""

import json
import os
import time
from configparser import ConfigParser, Error
from pathlib import Path

import boto3


BASE_DIR = Path(__file__).resolve().parent.parent
# パスワードをキャッシュする秒数。ローテーションの後は、接続の失敗で再取得する
CACHE_SECONDS = 300
_cache = {"password": None, "expires": 0.0}


def read_config(path=None):
    path = Path(path or os.getenv(
        "MIDORI_CONFIG", str(BASE_DIR / "config.ini")
    ))
    config = ConfigParser(interpolation=None)
    required = {
        "database": (
            "host", "port", "name", "user"
        ),
        "aws": ("region", "bucket"),
    }
    try:
        if not config.read(path, encoding="utf-8"):
            raise ValueError("設定ファイルが見つかりません")
        for section, keys in required.items():
            for key in keys:
                if not config.get(section, key).strip():
                    raise ValueError("設定に空の項目があります")
        port = config.getint("database", "port")
        if not 1 <= port <= 65535:
            raise ValueError("設定のポート番号が範囲外です")
    except (Error, ValueError) as exc:
        raise ValueError("設定ファイルを確認してください") from exc
    return config


def get_db_password(config=None, refresh=False):
    """Secrets Manager から DB のパスワードを取り出す（5分間キャッシュする）。"""
    config = config if config is not None else read_config()
    if (not refresh and _cache["password"]
            and time.monotonic() < _cache["expires"]):
        return _cache["password"]
    try:
        secret_id = config.get("database", "secret_id")
    except Error as exc:
        raise ValueError("DB のシークレットの設定がありません") from exc
    client = boto3.client(
        "secretsmanager", region_name=config.get("aws", "region")
    )
    value = client.get_secret_value(SecretId=secret_id)
    password = json.loads(value["SecretString"])["password"]
    _cache["password"] = password
    _cache["expires"] = time.monotonic() + CACHE_SECONDS
    return password
