"""Macie の動作確認用に、架空のカード番号の CSV を作る。"""
import csv
import random


def make_card_number():
    digits = [4] + [random.randint(0, 9) for _ in range(14)]
    total = 0
    for index, digit in enumerate(reversed(digits)):
        value = digit * 2 if index % 2 == 0 else digit
        total += value - 9 if value > 9 else value
    digits.append((10 - total % 10) % 10)
    return "".join(str(digit) for digit in digits)


with open("test-cards.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["name", "credit card number", "expiry"])
    for name in ["Taro Yamada", "Hanako Sato", "Jiro Suzuki"]:
        writer.writerow([name, make_card_number(), "12/29"])
