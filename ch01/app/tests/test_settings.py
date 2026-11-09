import pytest

from app.settings import get_db_password, read_config


def test_config_keeps_percent_and_explicit_path(tmp_path):
    path = tmp_path / "config.ini"
    path.write_text(
        "[database]\nhost=localhost\nport=5432\n"
        "name=midori\nuser=app\npassword=a%secret\n"
        "[aws]\nregion=ap-northeast-1\nbucket=example\n",
        encoding="utf-8",
    )
    config = read_config(path)
    assert config.getint("database", "port") == 5432
    assert get_db_password(config) == "a%secret"


def test_missing_config_has_clear_error(tmp_path):
    with pytest.raises(ValueError, match="設定"):
        read_config(tmp_path / "missing.ini")


def test_incomplete_config_has_clear_error(tmp_path):
    path = tmp_path / "config.ini"
    path.write_text("[database]\nhost=localhost\n")
    with pytest.raises(ValueError, match="設定"):
        read_config(path)


