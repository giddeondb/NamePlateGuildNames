#!/usr/bin/env python3
"""Build reproducible, installable addon ZIPs from an explicit file list."""
from pathlib import Path
import re
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
NAME = "NamePlateGuildNames"
FILES = (f"{NAME}.lua", f"{NAME}.toc", "README.md", "CHANGELOG.md", "LICENSE")


def build(root):
    toc = (root / f"{NAME}.toc").read_text()
    match = re.search(r"^## Version: (\d+\.\d+\.\d+)$", toc, re.MULTILINE)
    if not match:
        raise SystemExit("TOC must contain a semantic version")
    version = match.group(1)
    out = root / "dist"
    out.mkdir(exist_ok=True)
    archive = out / f"{NAME}.zip"
    with ZipFile(archive, "w", compression=ZIP_DEFLATED) as z:
        for filename in FILES:
            if (root / filename).is_symlink():
                raise RuntimeError(f"Refusing to package a symbolic link: {filename}")
            data = (root / filename).read_bytes()
            # Keep image links usable in the ZIP without shipping screenshots.
            if filename == "README.md":
                data = data.replace(b"](docs/images/", f"](https://raw.githubusercontent.com/giddeondb/{NAME}/v{version}/docs/images/".encode())
            info = ZipInfo(f"{NAME}/{filename}", (2026, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = ZIP_DEFLATED
            z.writestr(info, data)
    versioned = out / f"{NAME}-{version}.zip"
    versioned.write_bytes(archive.read_bytes())
    with ZipFile(archive) as z:
        if z.testzip() is not None or set(z.namelist()) != {f"{NAME}/{f}" for f in FILES}:
            raise RuntimeError("Invalid package contents")
    return versioned, archive


if __name__ == "__main__":
    for path in build(ROOT):
        print(path)
