import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_upstream as monitor

BASE = "a" * 40
HEAD = "b" * 40
FIRST = "packages/youtube_explode_dart/lib/client.dart"
SECOND = "packages/youtube_music_explode_dart/lib/music.dart"


def configuration():
    return {
        "schema_version": 1, "repository": "gokadzev/Musify", "branch": "master",
        "baseline_commit": BASE,
        "watched_paths": ["packages/youtube_explode_dart/lib/", SECOND],
    }


def entry(path, sha="c" * 40, mode="100644"):
    return {"path": path, "sha": sha, "mode": mode, "type": "blob"}


def tree(entries):
    return {"sha": "d" * 40, "truncated": False, "tree": entries}


class FakeAPI:
    def __init__(self, before=None, after=None, head=HEAD):
        self.before = before if before is not None else tree([entry(FIRST), entry(SECOND)])
        self.after = after if after is not None else self.before
        self.head = head
        self.calls = []

    def __call__(self, path):
        self.calls.append(path)
        if path.endswith("/commits/master"):
            return {"sha": self.head}
        if path.endswith(f"/git/trees/{BASE}?recursive=1"):
            return self.before
        if path.endswith(f"/git/trees/{HEAD}?recursive=1"):
            return self.after
        raise AssertionError(f"Unpinned or unexpected API call: {path}")


class SentinelTests(unittest.TestCase):
    def test_identical_snapshots_do_not_alert_on_local_fork_customizations(self):
        result = monitor.check_upstream(configuration(), FakeAPI())
        self.assertFalse(result["changed"])
        self.assertEqual(result["changes"], [])

    def test_added_removed_and_modified_files_are_detected(self):
        extra = "packages/youtube_explode_dart/lib/new_parser.dart"
        api = FakeAPI(after=tree([entry(FIRST, "e" * 40), entry(extra)]))
        result = monitor.check_upstream(configuration(), api)
        statuses = {change["path"]: change["status"] for change in result["changes"]}
        self.assertEqual(statuses, {FIRST: "modified", SECOND: "removed", extra: "added"})
        self.assertEqual(len(api.calls), 3)
        self.assertIn(f"{BASE}...{HEAD}", result["compare_url"])

    def test_new_upstream_files_inside_monitored_folders_are_not_missed(self):
        api = FakeAPI(after=tree([entry(FIRST), entry(SECOND), entry(FIRST + ".new")]))
        self.assertEqual(monitor.check_upstream(configuration(), api)["changes"][0]["status"], "added")

    def test_changes_outside_scope_do_not_trigger_email(self):
        api = FakeAPI(after=tree([entry(FIRST), entry(SECOND), entry("windows/runner.cpp")]))
        self.assertFalse(monitor.check_upstream(configuration(), api)["changed"])

    def test_renames_are_visible_as_removal_and_addition(self):
        api = FakeAPI(after=tree([entry(FIRST + ".renamed"), entry(SECOND)]))
        statuses = [change["status"] for change in monitor.check_upstream(configuration(), api)["changes"]]
        self.assertEqual(sorted(statuses), ["added", "removed"])

    def test_file_mode_changes_are_detected(self):
        api = FakeAPI(after=tree([entry(FIRST, mode="120000"), entry(SECOND)]))
        self.assertTrue(monitor.check_upstream(configuration(), api)["changed"])

    def test_same_head_reuses_validated_baseline_tree(self):
        api = FakeAPI(head=BASE)
        self.assertFalse(monitor.check_upstream(configuration(), api)["changed"])
        self.assertEqual(len(api.calls), 2)

    def test_incomplete_trees_fail_instead_of_false_alarms(self):
        for location in ("before", "after"):
            with self.subTest(location=location):
                api = FakeAPI()
                bad = tree([entry(FIRST), entry(SECOND)])
                bad["truncated"] = True
                setattr(api, location, bad)
                with self.assertRaises(monitor.MonitorError):
                    monitor.check_upstream(configuration(), api)

    def test_missing_baseline_path_is_configuration_error(self):
        api = FakeAPI(before=tree([entry(FIRST)]))
        with self.assertRaises(monitor.MonitorError):
            monitor.check_upstream(configuration(), api)

    def test_entire_monitored_folder_removed_is_a_real_change(self):
        result = monitor.check_upstream(configuration(), FakeAPI(after=tree([entry(SECOND)])))
        self.assertEqual(result["changes"][0]["status"], "removed")
        self.assertIn(f"/blob/{BASE}/", result["changes"][0]["source_url"])

    def test_tree_validation_rejects_bad_ids_duplicates_and_control_characters(self):
        for entries in ([entry(FIRST, "short")], [entry(FIRST), entry(FIRST)], [entry("bad\npath")]):
            with self.subTest(entries=entries):
                with self.assertRaises(monitor.MonitorError):
                    monitor.index_tree(tree(entries), configuration()["watched_paths"])

    def test_branch_must_resolve_to_full_commit_sha(self):
        with self.assertRaises(monitor.MonitorError):
            monitor.check_upstream(configuration(), FakeAPI(head="master"))

    def test_notice_contains_diff_and_file_history_without_source_contents(self):
        result = monitor.check_upstream(configuration(), FakeAPI(after=tree([entry(FIRST, "e" * 40), entry(SECOND)])))
        body = monitor.notification_text(result)
        self.assertIn(FIRST, body)
        self.assertIn(result["compare_url"], body)
        self.assertIn(f"/commits/{HEAD}/", body)
        self.assertNotIn("AIza", body)
        self.assertNotIn("piano_fork", body)

    def test_outputs_and_summary_are_generated_without_changing_config(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config_file = root / "config.json"
            original = json.dumps(configuration())
            config_file.write_text(original, encoding="utf-8")
            config = monitor.load_config(config_file)
            result = monitor.check_upstream(config, FakeAPI())
            output = root / "github-output"
            summary = root / "summary"
            with patch.dict(os.environ, {"GITHUB_OUTPUT": str(output), "GITHUB_STEP_SUMMARY": str(summary)}):
                monitor.write_result(result, root / "reports")
            self.assertIn("changed=false", output.read_text())
            self.assertEqual(config_file.read_text(), original)
            self.assertEqual(json.loads((root / "reports/result.json").read_text())["status"], "ok")
            self.assertIn("Sentinella upstream", summary.read_text())

    def test_invalid_config_does_not_start_comparison(self):
        for update in ({"baseline_commit": "master"}, {"watched_paths": ["../bad"]},
                       {"watched_paths": []}, {"watched_paths": [FIRST, FIRST]},
                       {"repository": "https://evil.example/repo"}, {"schema_version": 99}):
            with self.subTest(update=update), tempfile.TemporaryDirectory() as temporary:
                config = configuration() | update
                path = Path(temporary) / "config.json"
                path.write_text(json.dumps(config))
                with self.assertRaises(monitor.MonitorError):
                    monitor.load_config(path)

    def test_http_and_network_errors_are_not_source_changes_or_secret_leaks(self):
        for error in (HTTPError("https://api.github.com/test", 403, "Forbidden", {}, None),
                      URLError("offline"), TimeoutError()):
            with self.subTest(error=type(error)), patch("check_upstream.urlopen", side_effect=error):
                with self.assertRaises(monitor.MonitorError) as caught:
                    monitor.api_json("/repos/gokadzev/Musify/commits/master")
                self.assertNotIn("Bearer", str(caught.exception))

    def test_invalid_json_and_unexpected_schema_fail_closed(self):
        for payload in (b"not JSON", b"[]"):
            response = MagicMock()
            response.__enter__.return_value.status = 200
            response.__enter__.return_value.read.return_value = payload
            with patch("check_upstream.urlopen", return_value=response):
                with self.assertRaises(monitor.MonitorError):
                    monitor.api_json("/test")

    def test_failed_run_never_writes_a_success_report(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "config.json"
            config.write_text(json.dumps(configuration()))
            with patch("check_upstream.check_upstream", side_effect=monitor.MonitorError("API failed")), redirect_stderr(io.StringIO()):
                self.assertEqual(monitor.main(["--config", str(config), "--output-dir", str(root / "reports")]), 1)
            self.assertFalse((root / "reports/result.json").exists())


if __name__ == "__main__":
    unittest.main()
