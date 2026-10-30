"""Check actual PDF glyph sizes and clipping for text-fitting regressions."""

import argparse
import json

import pymupdf as fitz


def verify(pdf_path: str) -> dict:
    targets = {"(Ricketts)": [], "(Hatch)": [], "iiiiiiiiiiii": [], "WWWWWWWWWWWW": []}
    labels = 0
    with fitz.open(pdf_path) as document:
        for page in document:
            for drawing in page.get_drawings():
                fill = drawing.get("fill")
                if fill is None or any(component > 0.01 for component in fill):
                    continue
                for item in drawing["items"]:
                    if item[0] != "re":
                        continue
                    rectangle = item[1]
                    if abs(rectangle.width - 24 * 72 / 25.4) > 0.25 or abs(rectangle.height - 25 * 72 / 25.4) > 0.25:
                        continue
                    labels += 1
                    for block in page.get_text("dict", clip=rectangle)["blocks"]:
                        for line in block.get("lines", []):
                            for span in line["spans"]:
                                if span["size"] > 9.01:
                                    raise ValueError(f"Text was enlarged: {span['text']} at {span['size']:.3f} pt")
                                if not rectangle.contains(fitz.Rect(span["bbox"])):
                                    raise ValueError(f"Text extends outside its label: {span['text']}")
                                if span["text"] in targets:
                                    targets[span["text"]].append(span)
        if labels != 52:
            raise ValueError(f"Expected 52 labels, found {labels}")
    for name, spans in targets.items():
        if not spans:
            raise ValueError(f"Missing regression text: {name}")
        if name != "WWWWWWWWWWWW" and any(abs(span["size"] - 9) > 0.01 for span in spans):
            raise ValueError(f"Text that fits did not retain 9 pt: {name}")
    if any(span["size"] >= 9 for span in targets["WWWWWWWWWWWW"]):
        raise ValueError("The wide name was not reduced to fit")
    return {"labels": labels, "naturalSizeNames": ["(Ricketts)", "(Hatch)", "iiiiiiiiiiii"], "wideNameFits": True}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", help="Text-fitting fixture PDF")
    args = parser.parse_args()
    print(json.dumps(verify(args.pdf)))


if __name__ == "__main__":
    main()
