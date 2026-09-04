#!/usr/bin/env python3

import argparse
import hashlib
from pathlib import Path


REQUIRED_ASSETS = ("Tibia.dat", "Tibia.spr", "assets.sec", "tibia.otfi")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_manifest(manifest: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for line in manifest.read_text(encoding="ascii").splitlines():
        expected, name = line.split(maxsplit=1)
        name = name.strip()
        if name in entries:
            raise RuntimeError(f"Duplicate manifest entry: {name}")
        entries[name] = expected.lower()
    return entries


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="Client resource root containing data/things/781",
    )
    args = parser.parse_args()

    assets_dir = Path(args.root) / "data/things/781"
    manifest = assets_dir / "SHA256SUMS"
    if not manifest.is_file():
        raise RuntimeError(f"Missing asset manifest: {manifest}")

    entries = load_manifest(manifest)
    if set(entries) != set(REQUIRED_ASSETS):
        raise RuntimeError("SHA256SUMS must list exactly the four canonical 7.81 assets")

    for name in REQUIRED_ASSETS:
        path = assets_dir / name
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Missing canonical asset: {path}")

        with path.open("rb") as file:
            if file.readline().rstrip() == b"version https://git-lfs.github.com/spec/v1":
                raise RuntimeError(f"Git LFS pointer was not resolved: {path}")

        actual = sha256(path)
        if actual != entries[name]:
            raise RuntimeError(
                f"SHA-256 mismatch for {path}: expected {entries[name]}, got {actual}"
            )
        print(f"{actual}  {path}")


if __name__ == "__main__":
    main()
