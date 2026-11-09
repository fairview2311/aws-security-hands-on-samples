"""検索以外の SQL はすべてプレースホルダーを使う。"""

import psycopg
from psycopg.rows import dict_row

from app.settings import get_db_password, read_config


def connect():
    config = read_config()
    try:
        return _connect(config, get_db_password(config))
    except psycopg.OperationalError:
        # ローテーションでパスワードが変わったときは、再取得して1回だけ再試行する
        return _connect(config, get_db_password(config, refresh=True))


def _connect(config, password):
    database = config["database"]
    return psycopg.connect(
        host=database["host"],
        port=database.getint("port"),
        dbname=database["name"],
        user=database["user"],
        password=password,
        connect_timeout=5,
        row_factory=dict_row,
    )


def find_user(username):
    with connect() as conn:
        return conn.execute(
            "SELECT id, username, password_hash FROM users "
            "WHERE username = %s",
            (username,),
        ).fetchone()


def list_customers(query):
    sql = "SELECT * FROM customers"
    if query:
        # 演習用の脆弱性（第8章で直す）。本番で使わない
        sql += " WHERE name ILIKE '%" + query + "%'"
    sql += " ORDER BY id"
    with connect() as conn:
        return conn.execute(sql).fetchall()


def get_customer(customer_id):
    with connect() as conn:
        return conn.execute(
            "SELECT * FROM customers WHERE id = %s",
            (customer_id,),
        ).fetchone()


def save_memo(customer_id, memo):
    with connect() as conn:
        result = conn.execute(
            "UPDATE customers SET memo = %s WHERE id = %s",
            (memo, customer_id),
        )
        return result.rowcount == 1


def save_card(customer_id, key):
    with connect() as conn:
        result = conn.execute(
            "UPDATE customers SET card_key = %s WHERE id = %s",
            (key, customer_id),
        )
        return result.rowcount == 1


def get_logo_key():
    with connect() as conn:
        row = conn.execute(
            "SELECT logo_key FROM company_settings WHERE id = 1"
        ).fetchone()
        return row["logo_key"] if row else None


def save_logo(key):
    with connect() as conn:
        conn.execute(
            "INSERT INTO company_settings (id, logo_key) "
            "VALUES (1, %s) ON CONFLICT (id) DO UPDATE "
            "SET logo_key = EXCLUDED.logo_key",
            (key,),
        )
