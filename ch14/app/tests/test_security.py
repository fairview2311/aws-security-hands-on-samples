from app.security import hash_password, verify_password


def test_password_is_hashed_and_wrong_password_is_rejected():
    encoded = hash_password("lab-password")
    assert encoded.startswith("$argon2id$")
    assert "lab-password" not in encoded
    assert verify_password(encoded, "lab-password")
    assert not verify_password(encoded, "wrong-password")
    assert not verify_password("broken-hash", "lab-password")
