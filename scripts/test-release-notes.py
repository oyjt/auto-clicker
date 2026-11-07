import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("release_notes", Path(__file__).with_name("release-notes.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReleaseNotesTests(unittest.TestCase):
    def test_extracts_only_the_requested_version(self):
        changelog = "# Changelog\n\n## [Unreleased]\n\n- Future\n\n## [1.2.3] - 2026-11-07\n\n### Fixed\n\n- A fix\n\n## [1.2.2]\n\n- Older\n"
        self.assertEqual(module.release_notes(changelog, "1.2.3"),
                         "## [1.2.3] - 2026-11-07\n\n### Fixed\n\n- A fix\n")

    def test_rejects_invalid_missing_empty_and_duplicate_versions(self):
        for changelog, version in [
            ("## [1.2.3]\n- Change", "v1.2.3"),
            ("## [1.2.3]\n- Change", "../1.2.3"),
            ("## [Unreleased]\n- Change", "1.2.3"),
            ("## [1.2.3]\n\n### Added\n", "1.2.3"),
            ("## [1.2.3]\n- One\n## [1.2.3]\n- Two", "1.2.3"),
        ]:
            with self.subTest(changelog=changelog, version=version):
                with self.assertRaises(ValueError):
                    module.release_notes(changelog, version)


if __name__ == "__main__":
    unittest.main()
