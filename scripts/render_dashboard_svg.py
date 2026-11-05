from __future__ import annotations

import argparse
import csv
import html
from pathlib import Path


WIDTH = 1440
HEIGHT = 900
NAVY = "#12263A"
SLATE = "#526473"
LIGHT = "#F3F6F7"
GRID = "#D9E1E5"
TEAL = "#007C83"
GOLD = "#A86F00"
CORAL = "#C94B50"


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as source_file:
        return list(csv.DictReader(source_file))


def svg_text(x: float, y: float, value: str, size: int, color: str = NAVY, weight: int = 400) -> str:
    safe_value = html.escape(value)
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" font-family="Segoe UI, Arial, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" fill="{color}">{safe_value}</text>'
    )


def line_points(
    values: list[float],
    x: float,
    y: float,
    width: float,
    height: float,
    minimum: float,
    maximum: float,
) -> str:
    value_range = maximum - minimum or 1.0
    points: list[str] = []
    for index, value in enumerate(values):
        point_x = x + (index / (len(values) - 1)) * width
        point_y = y + height - ((value - minimum) / value_range) * height
        points.append(f"{point_x:.1f},{point_y:.1f}")
    return " ".join(points)


def render(industry_path: Path, peer_path: Path, output_path: Path) -> None:
    industry_rows = read_csv_rows(industry_path)
    peer_rows = read_csv_rows(peer_path)
    latest = industry_rows[-1]
    roa_values = [float(row["median_roa_pct"]) for row in industry_rows]
    nim_values = [float(row["median_nim_pct"]) for row in industry_rows]
    noncurrent_values = [float(row["median_noncurrent_loans_pct"]) for row in peer_rows]

    content: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}" role="img" aria-labelledby="title description">',
        '<title id="title">Bank Performance and Risk Early-Warning Scorecard preview</title>',
        '<desc id="description">Verified 2024 fourth-quarter FDIC metrics, a twenty-quarter profitability and margin trend, and noncurrent-loan medians by bank asset-size peer group.</desc>',
        '<rect width="1440" height="900" fill="#FFFFFF"/>',
        svg_text(64, 70, "Bank Performance & Risk Early-Warning Scorecard", 30, NAVY, 700),
        svg_text(64, 101, "FDIC BankFind • 2020 Q1–2024 Q4 • latest quarter shown", 15, SLATE, 400),
        svg_text(1190, 72, "2024 Q4", 22, TEAL, 700),
    ]

    cards = [
        ("Institutions", f"{int(latest['institution_count']):,}", NAVY),
        ("Median ROA", f"{float(latest['median_roa_pct']):.2f}%", TEAL),
        ("Median NIM", f"{float(latest['median_nim_pct']):.2f}%", TEAL),
        ("Loans / deposits", f"{float(latest['median_loans_to_deposits_pct']):.2f}%", GOLD),
        ("Noncurrent loans", f"{float(latest['median_noncurrent_loans_pct']):.3f}%", CORAL),
    ]
    for index, (label, value, color) in enumerate(cards):
        card_x = 64 + index * 260
        content.append(f'<rect x="{card_x}" y="135" width="232" height="112" rx="8" fill="{LIGHT}"/>')
        content.append(svg_text(card_x + 18, 173, label, 14, SLATE, 600))
        content.append(svg_text(card_x + 18, 222, value, 29, color, 700))

    content.extend([
        svg_text(64, 306, "Profitability recovered in 2024, while funding and credit pressure remained visible", 22, NAVY, 700),
        svg_text(64, 337, "Median metrics; peer and institution drill-down are required before action.", 14, SLATE, 400),
        '<rect x="64" y="370" width="820" height="360" rx="8" fill="#FFFFFF" stroke="#D9E1E5"/>',
        svg_text(88, 410, "Twenty-quarter median trend", 18, NAVY, 700),
        svg_text(88, 436, "ROA and net interest margin (%)", 13, SLATE, 400),
    ])

    chart_x, chart_y, chart_width, chart_height = 112, 475, 735, 190
    for grid_index in range(5):
        grid_y = chart_y + grid_index * (chart_height / 4)
        content.append(f'<line x1="{chart_x}" y1="{grid_y:.1f}" x2="{chart_x + chart_width}" y2="{grid_y:.1f}" stroke="{GRID}"/>')
    content.append(f'<polyline points="{line_points(roa_values, chart_x, chart_y, chart_width, chart_height, 0, 4)}" fill="none" stroke="{TEAL}" stroke-width="4"/>')
    content.append(f'<polyline points="{line_points(nim_values, chart_x, chart_y, chart_width, chart_height, 0, 4)}" fill="none" stroke="{GOLD}" stroke-width="4"/>')
    content.append(svg_text(112, 700, "2020 Q1", 12, SLATE, 400))
    content.append(svg_text(788, 700, "2024 Q4", 12, SLATE, 400))
    content.append(svg_text(620, 410, "ROA", 13, TEAL, 700))
    content.append(svg_text(690, 410, "NIM", 13, GOLD, 700))

    content.extend([
        '<rect x="916" y="370" width="460" height="360" rx="8" fill="#FFFFFF" stroke="#D9E1E5"/>',
        svg_text(940, 410, "Credit-quality peer comparison", 18, NAVY, 700),
        svg_text(940, 436, "Median noncurrent loans (%), 2024 Q4", 13, SLATE, 400),
    ])
    maximum_noncurrent = max(noncurrent_values)
    for index, peer_row in enumerate(peer_rows):
        bar_y = 480 + index * 56
        bar_width = (float(peer_row["median_noncurrent_loans_pct"]) / maximum_noncurrent) * 230
        content.append(svg_text(940, bar_y + 16, peer_row["asset_size_band"], 13, NAVY, 600))
        content.append(f'<rect x="1060" y="{bar_y}" width="{bar_width:.1f}" height="22" rx="3" fill="{CORAL}"/>')
        content.append(svg_text(1300, bar_y + 16, f"{float(peer_row['median_noncurrent_loans_pct']):.3f}%", 13, NAVY, 700))

    content.extend([
        '<rect x="64" y="760" width="1312" height="92" rx="8" fill="#F3F6F7"/>',
        svg_text(88, 795, "Recommended management action", 16, NAVY, 700),
        svg_text(88, 823, "Monitor funding intensity and credit quality together; investigate persistent peer outliers before changing limits or strategy.", 15, NAVY, 400),
        svg_text(88, 846, "Caveat: descriptive regulatory data do not predict failure or establish causation.", 13, SLATE, 400),
        '</svg>',
    ])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(content) + "\n", encoding="utf-8")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render an accessible static dashboard preview.")
    parser.add_argument("--industry", required=True, type=Path)
    parser.add_argument("--peers", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    render(arguments.industry.resolve(), arguments.peers.resolve(), arguments.output.resolve())


if __name__ == "__main__":
    main()
