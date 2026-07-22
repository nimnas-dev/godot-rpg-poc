#!/usr/bin/env python3
"""Lightweight, dependency-free Godot architecture audit.

This script reports structural review leads. It does not declare architecture
violations automatically; every finding requires project-context review.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class Finding:
    severity: str
    rule: str
    path: str
    line: int
    message: str


CHECKS = (
    (
        "warning",
        "absolute-root-reference",
        re.compile(r"(?:get_node\s*\(\s*[\"']/root/|[\"']/root/[A-Za-z_])"),
        "Absolute /root reference increases global coupling; verify that an Autoload is necessary.",
    ),
    (
        "warning",
        "ancestor-walk",
        re.compile(r"get_parent\s*\(\s*\)\s*\.\s*get_parent\s*\("),
        "Multiple parent traversal is fragile; inject the dependency or let the owner coordinate it.",
    ),
    (
        "warning",
        "deep-node-path",
        re.compile(r"get_node(?:_or_null)?\s*\(\s*[\"'][^\"']*(?:/[^/\"']+){3,}[\"']"),
        "Deep NodePath is fragile; consider a scene boundary, unique node, or injected reference.",
    ),
    (
        "info",
        "dynamic-tree-search",
        re.compile(r"\b(?:find_child|find_children)\s*\("),
        "Dynamic tree search can hide dependencies and be slow in hot paths.",
    ),
    (
        "info",
        "broad-group-query",
        re.compile(r"get_nodes_in_group\s*\("),
        "Broad group query should be cached or event-driven when used frequently.",
    ),
    (
        "info",
        "runtime-resource-load",
        re.compile(r"(?<!pre)load\s*\(\s*[\"']res://"),
        "Runtime load is valid, but avoid it in latency-sensitive paths and consider preload where appropriate.",
    ),
)


def relative(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def audit_script(path: Path, root: Path, max_lines: int) -> list[Finding]:
    findings: list[Finding] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        return findings

    rel = relative(path, root)
    if len(lines) > max_lines:
        findings.append(
            Finding(
                "info",
                "large-script",
                rel,
                1,
                f"Script has {len(lines)} lines; review whether it owns multiple responsibilities.",
            )
        )

    current_callback = ""
    callback_indent = 0
    for number, line in enumerate(lines, start=1):
        stripped = line.strip()
        indent = len(line) - len(line.lstrip())
        match = re.match(r"func\s+(_process|_physics_process)\s*\(", stripped)
        if match:
            current_callback = match.group(1)
            callback_indent = indent
        elif current_callback and stripped and indent <= callback_indent and not stripped.startswith("#"):
            current_callback = ""

        for severity, rule, pattern, message in CHECKS:
            if pattern.search(line):
                if current_callback and rule in {
                    "dynamic-tree-search",
                    "broad-group-query",
                    "runtime-resource-load",
                }:
                    severity = "warning"
                    message = f"{message} Found inside {current_callback}."
                findings.append(Finding(severity, rule, rel, number, message))
    return findings


def count_autoloads(project_file: Path) -> int:
    if not project_file.exists():
        return 0
    count = 0
    in_section = False
    for line in project_file.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("["):
            in_section = stripped == "[autoload]"
            continue
        if in_section and stripped and not stripped.startswith(";") and "=" in stripped:
            count += 1
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_root", nargs="?", default=".")
    parser.add_argument("--max-lines", type=int, default=500)
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()

    root = Path(args.project_root).expanduser().resolve()
    project_file = root / "project.godot"
    if not project_file.exists():
        print(f"ERROR: project.godot not found under {root}")
        return 2

    scripts = sorted(root.rglob("*.gd"))
    scenes = sorted(root.rglob("*.tscn"))
    findings: list[Finding] = []
    for script in scripts:
        if ".godot" in script.parts or ".codex" in script.parts:
            continue
        findings.extend(audit_script(script, root, args.max_lines))

    summary = {
        "root": root.as_posix(),
        "scripts": len([p for p in scripts if ".codex" not in p.parts]),
        "scenes": len(scenes),
        "autoloads": count_autoloads(project_file),
        "findings": len(findings),
    }

    if args.as_json:
        print(json.dumps({"summary": summary, "findings": [asdict(f) for f in findings]}, indent=2))
        return 0

    print("Godot architecture audit")
    print(json.dumps(summary, indent=2))
    for finding in findings:
        print(
            f"{finding.severity.upper():7} {finding.path}:{finding.line} "
            f"[{finding.rule}] {finding.message}"
        )
    print("Review findings in context; this audit intentionally avoids automatic rewrites.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
