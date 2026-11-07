"""Extract one version from CHANGELOG.md; fail before releasing undocumented builds."""
from pathlib import Path
import re
import sys


def release_notes(changelog, version):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError("Expected a version in X.Y.Z format (no v prefix).")
    sections = re.split(r"(?=^## \[)", changelog, flags=re.MULTILINE)
    matches = [section.strip() for section in sections
               if section.startswith(f"## [{version}]")]
    if len(matches) != 1:
        raise ValueError(f"CHANGELOG.md must contain exactly one ## [{version}] section.")
    notes = matches[0]
    if not any(line.strip() and not line.startswith("#") for line in notes.splitlines()[1:]):
        raise ValueError(f"CHANGELOG.md has no release notes for {version}.")
    return notes + "\n"


if __name__ == "__main__":
    try:
        if len(sys.argv) != 2:
            raise ValueError("Usage: python3 scripts/release-notes.py X.Y.Z")
        changelog = Path(__file__).resolve().parent.parent / "CHANGELOG.md"
        print(release_notes(changelog.read_text(encoding="utf-8"), sys.argv[1]), end="")
    except (OSError, ValueError) as error:
        sys.exit(str(error))
