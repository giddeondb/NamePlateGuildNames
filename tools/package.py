#!/usr/bin/env python3
"""Build reproducible, installable addon ZIPs from an explicit file list."""
from pathlib import Path
import re
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
NAME = "NamePlateGuildNames"
FILES = (f"{NAME}.lua", f"{NAME}.toc", "README.md", "CHANGELOG.md", "LICENSE")


def main():
    toc = (ROOT / f"{NAME}.toc").read_text()
    match = re.search(r"^## Version: (\d+\.\d+\.\d+)$", toc, re.MULTILINE)
    if not match:
        raise SystemExit("TOC must contain a semantic version")
    version = match.group(1)
    if f"v{version}" not in (ROOT / f"{NAME}.lua").read_text():
        raise SystemExit("Lua display version does not match the TOC")
    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    archive = out / f"{NAME}.zip"
    with ZipFile(archive, "w", compression=ZIP_DEFLATED) as z:
        for filename in FILES:
            data = (ROOT / filename).read_bytes()
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
    print(archive)
    print(versioned)


if __name__ == "__main__":
    main()
