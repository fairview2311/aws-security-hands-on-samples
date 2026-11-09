"""設定と、第4章で差し替えるパスワード取得処理。"""

import os
from configparser import ConfigParser, Error
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent


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


def get_db_password(config=None):
    config = config if config is not None else read_config()
    try:
        # 演習用の脆弱性（第4章で直す）。本番で使わない
        password = config.get("database", "password")
    except Error as exc:
        raise ValueError("DB パスワードの設定がありません") from exc
    if not password.strip():
        raise ValueError("DB パスワードの設定が空です")
    return password
