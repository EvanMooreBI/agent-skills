"""Validate and rasterize a Brigade Fire and Fury label PDF."""

import argparse
import json
import sys
from pathlib import Path

import pymupdf as fitz

LABEL_WIDTH_PT = 24 * 72 / 25.4
LABEL_HEIGHT_PT = 25 * 72 / 25.4
GEOMETRY_EPS = 0.25


def validate_geometry(manifest: dict) -> None:
    # Renderer metadata cannot authorize a different physical label size.
    if (manifest.get('labelWidthMm') != 24 or manifest.get('labelHeightMm') != 25
            or manifest.get('rendererMode') != 'local-24mm-by-25mm'
            or abs(float(manifest['labelWidthPt']) - LABEL_WIDTH_PT) > GEOMETRY_EPS
            or abs(float(manifest['labelHeightPt']) - LABEL_HEIGHT_PT) > GEOMETRY_EPS):
        raise ValueError('Manifest geometry must describe 24 x 25 mm local labels.')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate label PDF size, pages, and side markers, then render review images.",
        epilog="Example: validate_pdf.py labels.pdf manifest.json previews",
    )
    parser.add_argument("pdf", type=Path, help="Rendered label PDF")
    parser.add_argument("manifest", type=Path, help="JSON manifest from render-labels.js")
    parser.add_argument("preview_directory", type=Path, help="Directory for page PNG files")
    return parser.parse_args()


def load_manifest(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValueError(f"Manifest not found: {path}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"Manifest is not valid JSON: {path}") from error


def validate_source(pdf_path: Path, manifest: dict) -> fitz.Document:
    validate_geometry(manifest)
    if not pdf_path.is_file() or pdf_path.stat().st_size < 1_000:
        raise ValueError("PDF is missing or unexpectedly small.")
    document = fitz.open(pdf_path)
    if document.page_count != int(manifest["pageCount"]):
        raise ValueError(
            f"PDF page count {document.page_count} does not match expected {manifest['pageCount']}."
        )
    if document.page_count < 2:
        raise ValueError("Combined output must contain at least one page for each side.")
    return document


def matching_label_rectangles(page: fitz.Page, width: float, height: float) -> list[fitz.Rect]:
    rectangles: list[fitz.Rect] = []
    for drawing in page.get_drawings():
        fill = drawing.get("fill")
        if fill is None or any(component > 0.01 for component in fill):
            continue
        for item in drawing["items"]:
            if item[0] != "re":
                continue
            rectangle = item[1]
            if abs(rectangle.width - width) > GEOMETRY_EPS or abs(rectangle.height - height) > GEOMETRY_EPS:
                raise ValueError(f'Incorrect physical label dimensions: {rectangle.width:.3f}x{rectangle.height:.3f} pt.')
            rectangles.append(rectangle)
    return rectangles


def validate_pages(document: fitz.Document, manifest: dict, preview_directory: Path) -> int:
    validate_geometry(manifest)
    label_width = LABEL_WIDTH_PT
    label_height = LABEL_HEIGHT_PT
    expected_label_count = int(manifest["labelCount"])
    preview_directory.mkdir(parents=True, exist_ok=True)
    combined_text = []
    label_count = 0
    for index, page in enumerate(document):
        rectangle = page.rect
        if abs(rectangle.width - 792) > 1 or abs(rectangle.height - 612) > 1:
            raise ValueError(
                f"Page {index + 1} is {rectangle.width}x{rectangle.height}, not landscape US Letter."
            )
        combined_text.append(page.get_text())
        label_count += len(matching_label_rectangles(page, label_width, label_height))
        pixmap = page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), alpha=False)
        pixmap.save(preview_directory / f"page-{index + 1:03d}.png")
    text = "\n".join(combined_text)
    for marker in ("USA -", "CSA -"):
        if marker not in text:
            raise ValueError(f"PDF text does not contain required side marker: {marker}")
    if label_count != expected_label_count:
        raise ValueError(
            f"PDF contains {label_count} {label_width:.3f}x{label_height:.3f} pt black label rectangles, "
            f"not expected {expected_label_count}."
        )
    return label_count


def main() -> int:
    args = parse_args()
    try:
        manifest = load_manifest(args.manifest)
        document = validate_source(args.pdf, manifest)
        label_count = validate_pages(document, manifest, args.preview_directory)
        result = {
            "pages": document.page_count,
            "bytes": args.pdf.stat().st_size,
            "previewCount": document.page_count,
            "labelCount": label_count,
        }
        print(json.dumps(result))
        return 0
    except (ValueError, KeyError, TypeError, RuntimeError) as error:
        print(f"PDF validation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
