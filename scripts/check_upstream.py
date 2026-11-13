"""Read-only upstream sentinel; no package contents, merges or automatic baseline updates.

Only Git tree metadata is fetched. Blob IDs identify changes, not security guarantees.
Uses the Python standard library; compatible with Python 3.12+.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

API_ROOT = "https://api.github.com"
MAX_RESPONSE_BYTES = 8 * 1024 * 1024
SHA_PATTERN = re.compile(r"[0-9a-f]{40}")


class MonitorError(Exception):
    """A failed check must never be reported as an upstream source change."""


def valid_sha(value: object) -> bool:
    return isinstance(value, str) and SHA_PATTERN.fullmatch(value) is not None


def safe_path(value: object) -> bool:
    return (
        isinstance(value, str)
        and bool(value)
        and not value.startswith("/")
        and "\\" not in value
        and not any(ord(ch) < 32 or ord(ch) == 127 for ch in value)
        and all(part not in ("", ".", "..") for part in value.rstrip("/").split("/"))
    )


def load_config(path: Path) -> dict:
    try:
        config = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise MonitorError("Cannot read a valid monitor configuration.") from error
    if not isinstance(config, dict) or config.get("schema_version") != 1:
        raise MonitorError("Unsupported monitor configuration schema.")
    repository = config.get("repository", "")
    if not isinstance(repository, str) or not re.fullmatch(
        r"[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+", repository
    ) or repository.split("/")[-1] in (".", ".."):
        raise MonitorError("Invalid upstream repository.")
    branch = config.get("branch")
    if not isinstance(branch, str) or not branch or any(ord(c) < 33 for c in branch):
        raise MonitorError("Invalid upstream branch.")
    if not valid_sha(config.get("baseline_commit")):
        raise MonitorError("The baseline must be an explicit full commit SHA.")
    selectors = config.get("watched_paths")
    if not isinstance(selectors, list) or not selectors or not all(
        safe_path(path) for path in selectors
    ) or len(selectors) != len(set(selectors)):
        raise MonitorError("Invalid or duplicated monitored paths.")
    return config


def api_json(path: str) -> dict:
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "Musify-Upstream-Sentinel/1.0",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        with urlopen(Request(API_ROOT + path, headers=headers), timeout=20) as response:
            if response.status != 200:
                raise MonitorError(f"GitHub API check failed (HTTP {response.status}).")
            payload = response.read(MAX_RESPONSE_BYTES + 1)
    except HTTPError as error:
        # Do not print headers, tokens or arbitrary response bodies.
        raise MonitorError(f"GitHub API check failed (HTTP {error.code}).") from error
    except (URLError, TimeoutError, OSError) as error:
        raise MonitorError("GitHub API is unreachable or timed out.") from error
    if len(payload) > MAX_RESPONSE_BYTES:
        raise MonitorError("GitHub API response exceeds the safe size limit.")
    try:
        result = json.loads(payload)
    except (ValueError, UnicodeError) as error:
        raise MonitorError("GitHub API returned invalid JSON.") from error
    if not isinstance(result, dict):
        raise MonitorError("GitHub API returned an unexpected response schema.")
    return result


def is_watched(path: str, selectors: list[str]) -> bool:
    return any(path.startswith(selector) if selector.endswith("/") else path == selector
               for selector in selectors)


def index_tree(payload: dict, selectors: list[str]) -> dict:
    if not isinstance(payload, dict) or payload.get("truncated") is not False:
        raise MonitorError("Incomplete Git tree: refusing a potentially partial comparison.")
    if not valid_sha(payload.get("sha")) or not isinstance(payload.get("tree"), list):
        raise MonitorError("Invalid Git tree response.")
    indexed = {}
    seen = set()
    for entry in payload["tree"]:
        if not isinstance(entry, dict) or not safe_path(entry.get("path")):
            raise MonitorError("Invalid path in Git tree response.")
        path = entry["path"]
        if path in seen or not valid_sha(entry.get("sha")):
            raise MonitorError("Duplicate path or invalid object ID in Git tree.")
        seen.add(path)
        if entry.get("type") not in ("blob", "tree", "commit"):
            raise MonitorError("Unknown Git tree entry type.")
        if entry["type"] != "blob" or not is_watched(path, selectors):
            continue
        if entry.get("mode") not in ("100644", "100755", "120000"):
            raise MonitorError("Unsupported mode of a monitored file.")
        indexed[path] = {"sha": entry["sha"], "mode": entry["mode"]}
    return indexed


def check_upstream(config: dict, fetch: Callable[[str], dict] = api_json) -> dict:
    repository = config["repository"]
    baseline = config["baseline_commit"]
    prefix = f"/repos/{repository}"
    # Resolve the moving branch once; all subsequent reads use immutable SHAs.
    head_data = fetch(f"{prefix}/commits/{quote(config['branch'], safe='')}")
    head = head_data.get("sha")
    if not valid_sha(head):
        raise MonitorError("Cannot resolve an unambiguous upstream commit.")
    selectors = config["watched_paths"]
    before = index_tree(fetch(f"{prefix}/git/trees/{baseline}?recursive=1"), selectors)
    for selector in selectors:
        if not any(is_watched(path, [selector]) for path in before):
            raise MonitorError("A monitored path is absent from the reviewed baseline.")
    after = before if head == baseline else index_tree(
        fetch(f"{prefix}/git/trees/{head}?recursive=1"), selectors
    )
    changes = []
    web_root = f"https://github.com/{repository}"
    for path in sorted(before.keys() | after.keys()):
        old, new = before.get(path), after.get(path)
        if old == new:
            continue
        status = "added" if old is None else "removed" if new is None else "modified"
        revision = head if new is not None else baseline
        changes.append({
            "path": path, "status": status, "before": old, "after": new,
            "source_url": f"{web_root}/blob/{revision}/{quote(path, safe='/')}",
            "history_url": f"{web_root}/commits/{head}/{quote(path, safe='/')}",
        })
    return {
        "status": "ok", "repository": repository, "branch": config["branch"],
        "baseline_commit": baseline, "upstream_commit": head,
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "changed": bool(changes), "changes": changes,
        "compare_url": f"{web_root}/compare/{baseline}...{head}",
        "monitored_baseline_files": len(before), "monitored_current_files": len(after),
    }


def notification_text(result: dict) -> str:
    lines = [
        "Musify — sentinella upstream (sola segnalazione)", "",
        f"Repository: {result['repository']} ({result['branch']})",
        f"Baseline revisionata: {result['baseline_commit']}",
        f"Snapshot controllato: {result['upstream_commit']}",
        f"File monitorati modificati: {len(result['changes'])}",
        f"Confronto: {result['compare_url']}", "",
    ]
    for change in result["changes"]:
        lines.extend([
            f"[{change['status']}] {change['path']}",
            f"  Sorgente: {change['source_url']}",
            f"  Cronologia: {change['history_url']}",
        ])
    lines.extend([
        "", "Un cambiamento non dimostra un bug o una modifica critica.",
        "La baseline indica una revisione, non il porting di tutte le patch nel fork.",
        "Valutare parser/filtri e header/client con test prima di integrare codice.",
        "Nessun aggiornamento dell'app o della baseline viene applicato automaticamente.",
        "La stessa differenza verra segnalata ai controlli successivi finche non sara revisionata",
        "e la baseline aggiornata manualmente con una motivazione. Nessun file privato e allegato.",
    ])
    return "\n".join(lines) + "\n"


def write_result(result: dict, directory: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "result.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    report = notification_text(result)
    (directory / "notification.txt").write_text(report, encoding="utf-8")
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with Path(output).open("a", encoding="utf-8") as stream:
            stream.write(f"changed={str(result['changed']).lower()}\n")
            stream.write(f"change_count={len(result['changes'])}\n")
            stream.write(f"upstream_commit={result['upstream_commit']}\n")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with Path(summary).open("a", encoding="utf-8") as stream:
            stream.write("## Sentinella upstream\n\n")
            # Indented plain text prevents repository paths becoming workflow markup.
            stream.write("\n".join("    " + line for line in report.splitlines()) + "\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=Path(".github/upstream-monitor.json"))
    parser.add_argument("--output-dir", type=Path, default=Path("artifacts/upstream-monitor"))
    args = parser.parse_args(argv)
    try:
        result = check_upstream(load_config(args.config))
        write_result(result, args.output_dir)
    except (MonitorError, OSError) as error:
        print(f"Upstream monitor ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Upstream {result['upstream_commit']}: {len(result['changes'])} monitored changes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
