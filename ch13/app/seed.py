"""架空のユーザーと顧客を投入する。再実行しても増やさない。"""

import argparse
import os

from app.db import connect
from app.security import hash_password


NAMES = ("山田 太郎", "佐藤 花子", "みどり 次郎")
EMAILS = (
    "test@example.com", "test2@example.com", "test3@example.com"
)


SCHEMA = (
    """
    CREATE TABLE IF NOT EXISTS users (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS customers (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name TEXT NOT NULL,
        company TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        memo TEXT NOT NULL DEFAULT '',
        card_key TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS company_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        logo_key TEXT
    )
    """,
)


def seed(password):
    if not password or not password.strip():
        raise ValueError("ログイン用パスワードを指定してください")
    password_hash = hash_password(password)
    with connect() as conn:
        for statement in SCHEMA:
            conn.execute(statement)
        conn.execute(
            "INSERT INTO users (username, password_hash) "
            "VALUES (%s, %s) ON CONFLICT (username) "
            "DO UPDATE SET "
            "password_hash = EXCLUDED.password_hash",
            ("yamada-taro", password_hash),
        )
        for name, email in zip(NAMES, EMAILS):
            conn.execute(
                "INSERT INTO customers "
                "(name, company, email, phone, address, memo) "
                "VALUES (%s, %s, %s, %s, %s, %s) "
                "ON CONFLICT (email) DO NOTHING",
                (
                    name, "みどり文具株式会社", email,
                    "03-0000-0000", "東京都千代田区1-1-1",
                    "次回の訪問日を確認する",
                ),
            )
        conn.execute(
            "INSERT INTO company_settings (id) VALUES (1) "
            "ON CONFLICT (id) DO NOTHING"
        )


def main():
    parser = argparse.ArgumentParser(
        description="演習用の初期データを投入します"
    )
    parser.add_argument(
        "--password", help="ログイン用。MIDORI_SEED_PASSWORD でも指定可"
    )
    args = parser.parse_args()
    password = (
        args.password or os.getenv("MIDORI_SEED_PASSWORD")
    )
    if not password or not password.strip():
        parser.error("--password か MIDORI_SEED_PASSWORD が必要です")
    seed(password)
    print("初期データを投入しました。ユーザー名: yamada-taro")


if __name__ == "__main__":
    main()
