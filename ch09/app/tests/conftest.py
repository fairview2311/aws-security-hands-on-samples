import socket

import pytest


@pytest.fixture(autouse=True)
def prohibit_network(monkeypatch):
    def forbidden(*args, **kwargs):
        pytest.fail("テストから外部へ通信しました")

    monkeypatch.setattr(socket.socket, "connect", forbidden)
    monkeypatch.setattr(socket.socket, "connect_ex", forbidden)

@pytest.fixture(autouse=True)
def public_dns(monkeypatch):
    # テストでは名前解決をせず、公開のアドレスが返ったことにする
    monkeypatch.setattr(
        socket, "getaddrinfo",
        lambda *a, **kw: [(2, 1, 6, "", ("8.8.8.8", 0))],
    )
