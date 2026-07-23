#!/usr/bin/env python3
"""Read-only inventory for planning a Godot engine version migration."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


SKIP_DIRS = {".git", ".godot", ".import", "build", "dist"}
NATIVE_SUFFIXES = {".a", ".dll", ".dylib", ".framework", ".so"}
COUNTED_SUFFIXES = {
    ".cs",
    ".gd",
    ".gdshader",
    ".shader",
    ".tscn",
    ".tres",
    ".uid",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Inventory a Godot project before an engine migration. "
            "This script does not load, import, modify, or export the project."
        )
    )
    parser.add_argument("project_root", type=Path)
    parser.add_argument("--godot-bin", type=Path, help="Target Godot editor binary")
    parser.add_argument("--target-version", help="Planned exact target version")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of Markdown")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 when warnings exist; invalid projects always exit 2",
    )
    return parser.parse_args()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def scalar(text: str, key: str) -> str | None:
    match = re.search(rf"(?m)^{re.escape(key)}\s*=\s*(.+?)\s*$", text)
    if not match:
        return None
    value = match.group(1).strip()
    if len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1]
    return value


def packed_strings(text: str, key: str) -> list[str]:
    match = re.search(
        rf"(?s){re.escape(key)}\s*=\s*PackedStringArray\((.*?)\)",
        text,
    )
    return re.findall(r'"([^"]*)"', match.group(1)) if match else []


def iter_project_files(root: Path):
    for path in root.rglob("*"):
        if any(part in SKIP_DIRS for part in path.relative_to(root).parts):
            continue
        if path.is_file():
            yield path


def inspect_files(root: Path) -> dict[str, Any]:
    counts = {suffix: 0 for suffix in sorted(COUNTED_SUFFIXES)}
    gdextensions: list[str] = []
    plugins: list[str] = []
    native_libraries: list[str] = []
    dotnet_projects: list[str] = []
    class_names: list[dict[str, str]] = []

    for path in iter_project_files(root):
        relative = path.relative_to(root).as_posix()
        suffix = path.suffix.casefold()
        if suffix in counts:
            counts[suffix] += 1
        if suffix == ".gdextension":
            gdextensions.append(relative)
        if path.name == "plugin.cfg" and "addons" in path.parts:
            plugins.append(relative)
        if suffix in NATIVE_SUFFIXES:
            native_libraries.append(relative)
        if suffix in {".csproj", ".sln"}:
            dotnet_projects.append(relative)
        if suffix == ".gd":
            match = re.search(
                r"(?m)^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)",
                read_text(path),
            )
            if match:
                class_names.append({"name": match.group(1), "path": relative})

    return {
        "counts": counts,
        "gdextensions": sorted(gdextensions),
        "editor_plugins": sorted(plugins),
        "native_libraries": sorted(native_libraries),
        "dotnet_projects": sorted(dotnet_projects),
        "class_names": sorted(class_names, key=lambda item: item["name"].casefold()),
    }


def run_capture(command: list[str], timeout: int = 10) -> tuple[int, str]:
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        output = "\n".join(
            part.strip() for part in (result.stdout, result.stderr) if part.strip()
        )
        return result.returncode, output
    except (OSError, subprocess.TimeoutExpired) as error:
        return 127, str(error)


def locate_godot(explicit: Path | None) -> Path | None:
    if explicit:
        candidate = explicit.expanduser().resolve()
        return candidate if candidate.is_file() else None
    for name in ("godot", "godot4"):
        found = shutil.which(name)
        if found:
            return Path(found)
    mac_binary = Path("/Applications/Godot.app/Contents/MacOS/Godot")
    return mac_binary if mac_binary.is_file() else None


def inspect_engine(explicit: Path | None) -> dict[str, Any]:
    binary = locate_godot(explicit)
    if not binary:
        return {"binary": None, "version": None}
    code, output = run_capture([str(binary), "--version"])
    version = output.splitlines()[0].strip() if code == 0 and output else None
    return {"binary": str(binary), "version": version}


def git_summary(root: Path) -> dict[str, Any]:
    code, output = run_capture(["git", "-C", str(root), "status", "--short", "--branch"])
    if code != 0:
        return {"available": False, "clean": None, "summary": output}
    lines = output.splitlines()
    return {
        "available": True,
        "clean": len(lines) <= 1,
        "summary": output,
    }


def normalized_version(value: str | None) -> str | None:
    if not value:
        return None
    match = re.match(r"^(\d+\.\d+(?:\.\d+)?)", value)
    return match.group(1) if match else value


def build_report(args: argparse.Namespace) -> tuple[dict[str, Any], list[str]]:
    root = args.project_root.expanduser().resolve()
    project_file = root / "project.godot"
    if not project_file.is_file():
        raise FileNotFoundError(f"project.godot not found under {root}")

    text = read_text(project_file)
    project = {
        "root": str(root),
        "name": scalar(text, "config/name"),
        "features": packed_strings(text, "config/features"),
        "main_scene": scalar(text, "run/main_scene"),
        "renderer": scalar(text, "renderer/rendering_method"),
        "mobile_renderer": scalar(text, "renderer/rendering_method.mobile"),
        "physics_2d": scalar(text, "physics/2d/physics_engine"),
        "physics_3d": scalar(text, "physics/3d/physics_engine"),
        "target_version": args.target_version,
    }
    files = inspect_files(root)
    engine = inspect_engine(args.godot_bin)
    git = git_summary(root)
    warnings: list[str] = []

    if not project["main_scene"]:
        warnings.append("project.godot에 main scene이 없습니다.")
    if git["available"] and not git["clean"]:
        warnings.append("작업 트리가 dirty 상태입니다. 자동 변환 전에 변경을 보존·분리하세요.")
    if not engine["binary"]:
        warnings.append("검사할 target Godot editor binary를 찾지 못했습니다.")
    elif not engine["version"]:
        warnings.append("target Godot editor version을 확인하지 못했습니다.")

    feature_version = next(
        (
            value
            for value in project["features"]
            if re.fullmatch(r"\d+\.\d+(?:\.\d+)?", value)
        ),
        None,
    )
    engine_version = normalized_version(engine["version"])
    target_version = normalized_version(args.target_version)
    if feature_version and engine_version and not engine_version.startswith(feature_version):
        warnings.append(
            f"프로젝트 feature 버전({feature_version})과 검사한 editor({engine['version']})가 다릅니다."
        )
    if target_version and engine_version and not engine_version.startswith(target_version):
        warnings.append(
            f"요청한 target({args.target_version})과 검사한 editor({engine['version']})가 다릅니다."
        )
    if files["gdextensions"]:
        warnings.append("GDExtension API/ABI와 target engine 지원 범위를 검증해야 합니다.")
    if files["editor_plugins"]:
        warnings.append("Editor plugin의 target engine 지원 범위를 검증해야 합니다.")
    if files["native_libraries"]:
        warnings.append("Native library와 custom binary의 target engine 의존성을 검증해야 합니다.")
    if files["dotnet_projects"] and engine["version"]:
        lowered = engine["version"].casefold()
        if "mono" not in lowered and ".net" not in lowered:
            warnings.append(".NET project가 있지만 검사한 editor가 .NET build인지 확인할 수 없습니다.")

    report = {
        "schema_version": 2,
        "project": project,
        "git": git,
        "target_engine": engine,
        "files": files,
        "warnings": warnings,
        "proof_limit": (
            "Static inventory only; no project load, import, serialization change, "
            "runtime test, platform export, or release validation."
        ),
    }
    return report, warnings


def markdown(report: dict[str, Any]) -> str:
    project = report["project"]
    engine = report["target_engine"]
    lines = [
        "# Godot Engine Migration Preflight",
        "",
        f"- Project: {project['name'] or '(unnamed)'}",
        f"- Root: `{project['root']}`",
        f"- Features: {', '.join(project['features']) or '(none)'}",
        f"- Main scene: {project['main_scene'] or '(none)'}",
        f"- Renderer: {project['renderer'] or '(default)'}",
        f"- Mobile renderer: {project['mobile_renderer'] or '(default)'}",
        f"- Physics 2D: {project['physics_2d'] or '(default)'}",
        f"- Physics 3D: {project['physics_3d'] or '(default)'}",
        f"- Planned target: {project['target_version'] or '(not supplied)'}",
        f"- Target Godot binary: {engine['binary'] or '(not found)'}",
        f"- Target Godot version: {engine['version'] or '(unknown)'}",
        f"- Git clean: {report['git']['clean']}",
        "",
        "## Engine-sensitive inventory",
        "",
    ]
    for suffix, count in report["files"]["counts"].items():
        lines.append(f"- `{suffix}`: {count}")
    lines.extend(
        [
            f"- GDExtensions: {len(report['files']['gdextensions'])}",
            f"- Editor plugins: {len(report['files']['editor_plugins'])}",
            f"- .NET projects: {len(report['files']['dotnet_projects'])}",
            f"- Native libraries: {len(report['files']['native_libraries'])}",
            f"- Global class names: {len(report['files']['class_names'])}",
            "",
            "## Warnings",
            "",
        ]
    )
    if report["warnings"]:
        lines.extend(f"- {warning}" for warning in report["warnings"])
    else:
        lines.append("- (none)")
    lines.extend(["", f"> {report['proof_limit']}"])
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    try:
        report, warnings = build_report(args)
    except (FileNotFoundError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(json.dumps(report, ensure_ascii=False, indent=2) if args.json else markdown(report))
    return 1 if args.strict and warnings else 0


if __name__ == "__main__":
    raise SystemExit(main())
