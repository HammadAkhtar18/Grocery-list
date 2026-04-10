from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "assets" / "icons"
FULL_ICON_PATH = ICON_DIR / "app_icon.png"
FOREGROUND_ICON_PATH = ICON_DIR / "app_icon_foreground.png"
FULL_SVG_PATH = ICON_DIR / "app_icon.svg"
FOREGROUND_SVG_PATH = ICON_DIR / "app_icon_foreground.svg"
CANVAS_SIZE = 1024
INNER_SCALE = 0.66

GREEN = "#4CAF50"
DARK_GREEN = "#2E7D32"
LIGHT_GREEN = "#81C784"
WHITE = "#FFFFFF"
CREAM = "#F7F4EA"
ORANGE = "#FFB74D"
RED = "#EF5350"


def draw_full_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), WHITE)
    draw = ImageDraw.Draw(image)
    _draw_background_card(draw, size, WHITE, CREAM)
    _draw_bag_icon(
        draw=draw,
        size=size,
        bag_color=GREEN,
        accent_color=DARK_GREEN,
        produce_colors=(ORANGE, RED, LIGHT_GREEN),
    )
    return image


def draw_foreground_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    inner_size = int(size * INNER_SCALE)
    offset = (size - inner_size) // 2
    _draw_bag_icon(
        draw=draw,
        size=inner_size,
        bag_color=WHITE,
        accent_color=DARK_GREEN,
        produce_colors=(LIGHT_GREEN, ORANGE, RED),
        origin=(offset, offset),
    )
    return image


def _draw_background_card(draw: ImageDraw.ImageDraw, size: int, fill: str, border: str) -> None:
    margin = int(size * 0.09)
    radius = int(size * 0.22)
    draw.rounded_rectangle(
        (margin, margin, size - margin, size - margin),
        radius=radius,
        fill=fill,
        outline=border,
        width=max(8, size // 80),
    )


def _draw_bag_icon(
    draw: ImageDraw.ImageDraw,
    size: int,
    bag_color: str,
    accent_color: str,
    produce_colors: Iterable[str],
    origin: tuple[int, int] = (0, 0),
) -> None:
    ox, oy = origin
    stroke = max(12, size // 42)

    bag_left = ox + int(size * 0.24)
    bag_top = oy + int(size * 0.34)
    bag_right = ox + int(size * 0.76)
    bag_bottom = oy + int(size * 0.80)
    bag_radius = int(size * 0.08)

    draw.rounded_rectangle(
        (bag_left, bag_top, bag_right, bag_bottom),
        radius=bag_radius,
        fill=bag_color,
    )

    handle_left = ox + int(size * 0.34)
    handle_top = oy + int(size * 0.16)
    handle_right = ox + int(size * 0.66)
    handle_bottom = oy + int(size * 0.44)
    draw.arc(
        (handle_left, handle_top, handle_right, handle_bottom),
        start=200,
        end=340,
        fill=bag_color,
        width=stroke,
    )

    draw.line(
        [
            (ox + int(size * 0.39), oy + int(size * 0.31)),
            (ox + int(size * 0.36), oy + int(size * 0.40)),
        ],
        fill=bag_color,
        width=stroke,
    )
    draw.line(
        [
            (ox + int(size * 0.61), oy + int(size * 0.31)),
            (ox + int(size * 0.64), oy + int(size * 0.40)),
        ],
        fill=bag_color,
        width=stroke,
    )

    accent_y = oy + int(size * 0.53)
    draw.arc(
        (
            ox + int(size * 0.36),
            oy + int(size * 0.47),
            ox + int(size * 0.64),
            oy + int(size * 0.66),
        ),
        start=200,
        end=340,
        fill=accent_color,
        width=max(8, stroke // 2),
    )
    draw.line(
        [
            (ox + int(size * 0.40), accent_y),
            (ox + int(size * 0.60), accent_y),
        ],
        fill=accent_color,
        width=max(8, stroke // 2),
    )

    produce_centers = [
        (ox + int(size * 0.39), oy + int(size * 0.42)),
        (ox + int(size * 0.50), oy + int(size * 0.37)),
        (ox + int(size * 0.61), oy + int(size * 0.43)),
    ]
    produce_radius = int(size * 0.055)
    for color, center in zip(produce_colors, produce_centers, strict=True):
        cx, cy = center
        draw.ellipse(
            (
                cx - produce_radius,
                cy - produce_radius,
                cx + produce_radius,
                cy + produce_radius,
            ),
            fill=color,
        )

    leaf_points = [
        (ox + int(size * 0.51), oy + int(size * 0.25)),
        (ox + int(size * 0.57), oy + int(size * 0.18)),
        (ox + int(size * 0.63), oy + int(size * 0.24)),
        (ox + int(size * 0.56), oy + int(size * 0.29)),
    ]
    draw.polygon(leaf_points, fill=LIGHT_GREEN if bag_color == WHITE else DARK_GREEN)


def build_full_svg() -> str:
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" fill="#FFFFFF"/>
  <rect x="92" y="92" width="840" height="840" rx="225" fill="#FFFFFF" stroke="#F7F4EA" stroke-width="12"/>
  <path d="M389 318c-15 0-27-12-27-27 0-83 68-151 150-151s150 68 150 151c0 15-12 27-27 27s-27-12-27-27c0-53-43-96-96-96s-96 43-96 96c0 15-12 27-27 27z" fill="#4CAF50"/>
  <path d="M373 348h278c20 0 37 17 37 37v380c0 40-32 72-72 72H408c-40 0-72-32-72-72V385c0-20 17-37 37-37z" fill="#4CAF50"/>
  <circle cx="399" cy="430" r="56" fill="#FFB74D"/>
  <circle cx="512" cy="381" r="56" fill="#EF5350"/>
  <circle cx="625" cy="435" r="56" fill="#81C784"/>
  <path d="M524 246l54-60 59 54-56 48z" fill="#2E7D32"/>
  <path d="M410 540c20-46 183-46 204 0" fill="none" stroke="#2E7D32" stroke-width="26" stroke-linecap="round"/>
  <path d="M419 550h186" fill="none" stroke="#2E7D32" stroke-width="18" stroke-linecap="round"/>
</svg>
"""


def build_foreground_svg() -> str:
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <g transform="translate(174 174)">
    <path d="M218 145c-15 0-27-12-27-27 0-83 68-151 150-151s150 68 150 151c0 15-12 27-27 27s-27-12-27-27c0-53-43-96-96-96s-96 43-96 96c0 15-12 27-27 27z" fill="#FFFFFF"/>
    <path d="M202 175h278c20 0 37 17 37 37v380c0 40-32 72-72 72H237c-40 0-72-32-72-72V212c0-20 17-37 37-37z" fill="#FFFFFF"/>
    <circle cx="228" cy="257" r="56" fill="#81C784"/>
    <circle cx="341" cy="208" r="56" fill="#FFB74D"/>
    <circle cx="454" cy="262" r="56" fill="#EF5350"/>
    <path d="M353 73l54-60 59 54-56 48z" fill="#2E7D32"/>
    <path d="M239 367c20-46 183-46 204 0" fill="none" stroke="#2E7D32" stroke-width="26" stroke-linecap="round"/>
    <path d="M248 377h186" fill="none" stroke="#2E7D32" stroke-width="18" stroke-linecap="round"/>
  </g>
</svg>
"""


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    FULL_ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    draw_full_icon(CANVAS_SIZE).save(FULL_ICON_PATH)
    draw_foreground_icon(CANVAS_SIZE).save(FOREGROUND_ICON_PATH)

    FULL_SVG_PATH.write_text(build_full_svg(), encoding="utf-8")
    FOREGROUND_SVG_PATH.write_text(build_foreground_svg(), encoding="utf-8")

    print(f"Generated {FULL_ICON_PATH}")
    print(f"Generated {FOREGROUND_ICON_PATH}")
    print(f"Generated {FULL_SVG_PATH}")
    print(f"Generated {FOREGROUND_SVG_PATH}")


if __name__ == "__main__":
    main()
