#!/usr/bin/env python3
"""Generates UPC-A barcode PNG fixtures for Phase 1 testing (EQ-P1/EQ-S4).

Encodes real UPC-A bar patterns (not just an image with digits printed on
it) so the generated PNGs are actually decodable by a real barcode reader,
including ML Kit's, in the on-device integration test (AT1.2) and when
printed for the manual test script (MT1.1).

The barcode list below must stay in sync with
app/lib/data/seed_catalog.dart — it's intentionally a plain duplicated
list rather than parsed from the Dart source, since this is a one-off dev
tool, not part of the shipped app.

Usage: python3 tool/generate_barcode_fixtures.py
Requires: Pillow (already present on the dev machine as of this writing).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# (barcode, product name) - keep in sync with seedCatalog in
# app/lib/data/seed_catalog.dart.
SEED_CATALOG = [
    ("100000000014", "Whole Milk, 1 Gal"),
    ("100000000021", "2% Milk, 1 Gal"),
    ("100000000038", "Thomas's English Muffins"),
    ("100000000045", "Panko Bread Crumbs"),
    ("100000000052", "Creamy Peanut Butter"),
    ("100000000069", "Sourdough Bread"),
    ("100000000076", "Large Eggs, Dozen"),
    ("100000000083", "Salted Butter"),
    ("100000000090", "Roma Tomatoes"),
    ("100000000106", "Yellow Onion"),
    ("100000000113", "Ground Coffee, Medium Roast"),
    ("100000000120", "Orange Juice, 64oz"),
]

# A code deliberately NOT in the seed catalog, for the "not found" test
# case (SCAN-8 manual-identification fallback). Its checksum is still
# valid so it decodes fine; it's just absent from seedCatalog.
NOT_IN_CATALOG = ("999999999993", "(not in catalog - manual add fallback)")

# Standard UPC-A L-code (odd parity) patterns, digits 0-9, 7 modules each.
L_CODE = [
    "0001101", "0011001", "0010011", "0111101", "0100011",
    "0110001", "0101111", "0111011", "0110111", "0001011",
]
# R-code is the bitwise complement of L-code.
R_CODE = ["".join("1" if b == "0" else "0" for b in pattern) for pattern in L_CODE]

START_GUARD = "101"
MIDDLE_GUARD = "01010"
END_GUARD = "101"


def check_digit(digits11: str) -> int:
    odd = sum(int(d) for d in digits11[0::2])
    even = sum(int(d) for d in digits11[1::2])
    total = odd * 3 + even
    return (10 - (total % 10)) % 10


def encode_modules(code12: str) -> str:
    """Returns the full 95-module bar/space string for a 12-digit UPC-A code."""
    if len(code12) != 12 or not code12.isdigit():
        raise ValueError(f"expected 12 digits, got {code12!r}")
    expected_check = check_digit(code12[:11])
    if int(code12[11]) != expected_check:
        raise ValueError(
            f"{code12}: invalid checksum (expected {expected_check}, got {code12[11]})"
        )

    left = code12[:6]
    right = code12[6:]
    modules = START_GUARD
    modules += "".join(L_CODE[int(d)] for d in left)
    modules += MIDDLE_GUARD
    modules += "".join(R_CODE[int(d)] for d in right)
    modules += END_GUARD
    assert len(modules) == 95, len(modules)
    return modules


def render(code12: str, out_path: Path, module_px: int = 4, bar_height_px: int = 220) -> None:
    modules = encode_modules(code12)
    quiet_zone = module_px * 10
    width = quiet_zone * 2 + module_px * len(modules)
    text_height = 36
    height = bar_height_px + text_height

    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)

    x = quiet_zone
    for module in modules:
        if module == "1":
            draw.rectangle([x, 0, x + module_px - 1, bar_height_px], fill="black")
        x += module_px

    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 24)
    except OSError:
        font = ImageFont.load_default()
    text = code12
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(
        ((width - text_width) / 2, bar_height_px + 4),
        text,
        fill="black",
        font=font,
    )

    image.save(out_path)


def main() -> None:
    out_dir = Path(__file__).resolve().parent.parent / "test" / "fixtures" / "barcodes"
    out_dir.mkdir(parents=True, exist_ok=True)

    all_codes = SEED_CATALOG + [NOT_IN_CATALOG]
    for code, name in all_codes:
        out_path = out_dir / f"{code}.png"
        render(code, out_path)
        print(f"wrote {out_path.name}  ({name})")


if __name__ == "__main__":
    main()
