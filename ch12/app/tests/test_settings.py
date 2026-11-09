import pytest

from app.settings import get_db_password, read_config


class FakeSecretsManager:
    def get_secret_value(self, SecretId):
        assert SecretId == "rds!db-example"
        return {"SecretString": '{"username": "app", "password": "a%secret"}'}


def test_password_comes_from_secrets_manager(tmp_path, monkeypatch):
    path = tmp_path / "config.ini"
    path.write_text(
        "[database]\nhost=localhost\nport=5432\n"
        "name=midori\nuser=app\nsecret_id=rds!db-example\n"
        "[aws]\nregion=ap-northeast-1\nbucket=example\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(
        "app.settings.boto3.client", lambda *a, **k: FakeSecretsManager()
    )
    config = read_config(path)
    assert config.getint("database", "port") == 5432
    assert get_db_password(config, refresh=True) == "a%secret"


def test_missing_config_has_clear_error(tmp_path):
    with pytest.raises(ValueError, match="設定"):
        read_config(tmp_path / "missing.ini")


def test_incomplete_config_has_clear_error(tmp_path):
    path = tmp_path / "config.ini"
    path.write_text("[database]\nhost=localhost\n")
    with pytest.raises(ValueError, match="設定"):
        read_config(path)
