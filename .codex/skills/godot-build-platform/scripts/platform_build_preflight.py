#!/usr/bin/env python3
"""Read-only Godot platform build inventory that never reads credential contents."""

from __future__ import annotations

import argparse
import configparser
import json
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


PUBLIC_OPTIONS = (
    "application/unique_name",
    "application/package_name",
    "application/bundle_identifier",
    "application/short_version",
    "application/version",
    "application/version_code",
    "application/version_name",
    "application/min_ios_version",
    "application/min_macos_version",
    "architectures/arm64-v8a",
    "architectures/armeabi-v7a",
    "architectures/x86_64",
    "binary_format/architecture",
    "codesign/enable",
    "gradle_build/use_gradle_build",
    "progressive_web_app/enabled",
    "variant/extensions_support",
    "variant/thread_support",
)
SECRET_MARKERS = (
    "api_key",
    "certificate",
    "credential",
    "encryption",
    "identity",
    "key",
    "keystore",
    "password",
    "profile",
    "secret",
    "token",
)
EXPECTED_SUFFIXES = {
    "Android": {".apk", ".aab"},
    "iOS": {".zip"},
    "Web": {".html", ".zip"},
    "Windows": {".exe"},
    "macOS": {".app", ".zip", ".dmg"},
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Inventory Godot export presets, matching templates, and host tools. "
            "No project export, signing, install, or credential read is performed."
        )
    )
    parser.add_argument("project_root", type=Path)
    parser.add_argument("--godot-bin", type=Path, help="Exact Godot editor binary")
    parser.add_argument(
        "--platform",
        action="append",
        default=[],
        help="Target platform to inspect; repeat for multiple targets",
    )
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


def clean_value(value: str) -> str:
    return value.strip().strip('"')


def canonical_platform(value: str) -> str:
    lowered = value.casefold()
    if "android" in lowered:
        return "Android"
    if lowered in {"ios", "iphone", "ipad"} or "ios" in lowered:
        return "iOS"
    if "web" in lowered or "html5" in lowered:
        return "Web"
    if "windows" in lowered:
        return "Windows"
    if "macos" in lowered or "osx" in lowered or "mac os" in lowered:
        return "macOS"
    if "linux" in lowered or "bsd" in lowered:
        return "Linux"
    return value


def inspect_presets(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        return []

    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read_string(read_text(path))
    presets: list[dict[str, Any]] = []

    for section in parser.sections():
        if not re.fullmatch(r"preset\.\d+", section):
            continue
        values = parser[section]
        raw_platform = clean_value(values.get("platform", ""))
        preset: dict[str, Any] = {
            "name": clean_value(values.get("name", "")),
            "platform": canonical_platform(raw_platform),
            "platform_raw": raw_platform,
            "runnable": clean_value(values.get("runnable", "")),
            "dedicated_server": clean_value(values.get("dedicated_server", "")),
            "export_path": clean_value(values.get("export_path", "")),
        }
        option_section = f"{section}.options"
        options = parser[option_section] if parser.has_section(option_section) else {}
        public: dict[str, str] = {}
        for key in PUBLIC_OPTIONS:
            if key not in options or any(marker in key.casefold() for marker in SECRET_MARKERS):
                continue
            public[key] = clean_value(str(options[key]))
        if public:
            preset["public_options"] = public
        presets.append(preset)

    return presets


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


def template_version(engine_version: str | None) -> str | None:
    if not engine_version:
        return None
    match = re.match(
        r"^(\d+\.\d+(?:\.\d+)?\.(?:stable|beta\d*|rc\d*|dev\d*))",
        engine_version,
    )
    return match.group(1) if match else None


def template_root() -> Path | None:
    system = platform.system()
    if system == "Darwin":
        return Path.home() / "Library/Application Support/Godot/export_templates"
    if system == "Windows":
        appdata = os.environ.get("APPDATA")
        return Path(appdata) / "Godot/export_templates" if appdata else None
    return Path.home() / ".local/share/godot/export_templates"


def inspect_engine(explicit: Path | None) -> dict[str, Any]:
    binary = locate_godot(explicit)
    if not binary:
        return {
            "binary": None,
            "version": None,
            "matching_template_dir": None,
            "template_file_count": 0,
        }
    code, output = run_capture([str(binary), "--version"])
    version = output.splitlines()[0].strip() if code == 0 and output else None
    version_dir = template_version(version)
    root = template_root()
    exact_dir = root / version_dir if root and version_dir else None
    count = (
        sum(1 for path in exact_dir.iterdir() if path.is_file())
        if exact_dir and exact_dir.is_dir()
        else 0
    )
    return {
        "binary": str(binary),
        "version": version,
        "matching_template_dir": str(exact_dir) if exact_dir else None,
        "template_file_count": count,
    }


def inspect_tools() -> dict[str, bool]:
    names = (
        "adb",
        "codesign",
        "java",
        "keytool",
        "osslsigncode",
        "sdkmanager",
        "signtool",
        "xcodebuild",
        "xcrun",
    )
    return {name: shutil.which(name) is not None for name in names}


def git_tracked(root: Path, relative_path: str) -> bool | None:
    code, _ = run_capture(
        ["git", "-C", str(root), "ls-files", "--error-unmatch", "--", relative_path]
    )
    if code == 0:
        return True
    probe_code, _ = run_capture(["git", "-C", str(root), "rev-parse", "--git-dir"])
    return False if probe_code == 0 else None


def suffix_warning(preset: dict[str, Any]) -> str | None:
    export_path = preset.get("export_path", "")
    target = preset.get("platform", "")
    if not export_path or target not in EXPECTED_SUFFIXES:
        return None
    suffix = Path(export_path).suffix.casefold()
    if suffix not in EXPECTED_SUFFIXES[target]:
        expected = ", ".join(sorted(EXPECTED_SUFFIXES[target]))
        return (
            f"{preset.get('name') or '(unnamed)'} preset의 export_path 확장자"
            f"({suffix or '(none)'})를 {target} 기대 형식({expected})과 대조하세요."
        )
    return None


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
    }
    all_presets = inspect_presets(root / "export_presets.cfg")
    requested = {canonical_platform(value) for value in args.platform}
    presets = [
        preset
        for preset in all_presets
        if not requested or preset["platform"] in requested
    ]
    detected = {preset["platform"] for preset in presets if preset["platform"]}
    engine = inspect_engine(args.godot_bin)
    tools = inspect_tools()
    credential_file = root / ".godot/export_credentials.cfg"
    credentials = {
        "present": credential_file.is_file(),
        "tracked": git_tracked(root, ".godot/export_credentials.cfg"),
        "contents_read": False,
    }
    warnings: list[str] = []

    if not project["main_scene"]:
        warnings.append("project.godot에 main scene이 없습니다.")
    if not all_presets:
        warnings.append("export_presets.cfg 또는 export preset이 없습니다.")
    for target in sorted(requested):
        if target not in detected:
            warnings.append(f"요청한 {target} export preset을 찾지 못했습니다.")
    if not engine["binary"]:
        warnings.append("Godot editor binary를 찾지 못했습니다.")
    elif not engine["version"]:
        warnings.append("Godot editor version을 확인하지 못했습니다.")
    elif engine["template_file_count"] == 0:
        warnings.append("검사한 editor와 정확히 일치하는 export template을 찾지 못했습니다.")
    feature_version = next(
        (
            value
            for value in project["features"]
            if re.fullmatch(r"\d+\.\d+(?:\.\d+)?", value)
        ),
        None,
    )
    if (
        feature_version
        and engine["version"]
        and not engine["version"].startswith(feature_version + ".")
    ):
        warnings.append(
            f"프로젝트 feature 버전({feature_version})과 build editor"
            f"({engine['version']})가 다릅니다. 먼저 engine migration 범위를 확인하세요."
        )
    if credentials["tracked"]:
        warnings.append(
            ".godot/export_credentials.cfg가 Git에 추적됩니다. confidential 설정 노출을 검토하세요."
        )

    for preset in presets:
        warning = suffix_warning(preset)
        if warning:
            warnings.append(warning)

    if "Android" in detected:
        for tool in ("java", "keytool", "adb"):
            if not tools[tool]:
                warnings.append(f"Android target에 필요한 {tool} 실행 파일을 찾지 못했습니다.")
        if not (os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")):
            warnings.append("ANDROID_HOME 또는 ANDROID_SDK_ROOT가 설정되지 않았습니다.")
    if "iOS" in detected:
        if platform.system() != "Darwin":
            warnings.append("iOS export·archive 최종 검증에는 macOS host가 필요합니다.")
        for tool in ("xcodebuild", "xcrun"):
            if not tools[tool]:
                warnings.append(f"iOS target에 필요한 {tool} 실행 파일을 찾지 못했습니다.")
    if "macOS" in detected:
        for tool in ("codesign", "xcrun"):
            if not tools[tool]:
                warnings.append(f"macOS release 검증 도구 {tool}을 찾지 못했습니다.")
    if "Windows" in detected and not (tools["signtool"] or tools["osslsigncode"]):
        warnings.append(
            "Windows release signing 도구(SignTool 또는 osslsigncode)를 찾지 못했습니다."
        )
    if "Web" in detected:
        renderers = {project["renderer"], project["mobile_renderer"]}
        if "gl_compatibility" not in renderers:
            warnings.append(
                "Web target은 목표 Godot 버전의 Compatibility renderer 요구를 확인해야 합니다."
            )

    report = {
        "schema_version": 1,
        "host": {
            "system": platform.system(),
            "machine": platform.machine(),
            "android_sdk_env_configured": bool(
                os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
            ),
        },
        "project": project,
        "engine": engine,
        "requested_platforms": sorted(requested),
        "export_presets": presets,
        "credentials": credentials,
        "host_tools": tools,
        "warnings": warnings,
        "proof_limit": (
            "Static inventory only; no project load, export, artifact inspection, "
            "signing, install, launch, hosting, or store validation."
        ),
    }
    return report, warnings


def markdown(report: dict[str, Any]) -> str:
    project = report["project"]
    engine = report["engine"]
    lines = [
        "# Godot Platform Build Preflight",
        "",
        f"- Project: {project['name'] or '(unnamed)'}",
        f"- Root: `{project['root']}`",
        f"- Features: {', '.join(project['features']) or '(none)'}",
        f"- Main scene: {project['main_scene'] or '(none)'}",
        f"- Renderer: {project['renderer'] or '(default)'}",
        f"- Mobile renderer: {project['mobile_renderer'] or '(default)'}",
        f"- Host: {report['host']['system']} {report['host']['machine']}",
        f"- Godot binary: {engine['binary'] or '(not found)'}",
        f"- Godot version: {engine['version'] or '(unknown)'}",
        f"- Matching template files: {engine['template_file_count']}",
        f"- Credential file present: {report['credentials']['present']}",
        f"- Credential contents read: {report['credentials']['contents_read']}",
        "",
        "## Export presets",
        "",
    ]
    if report["export_presets"]:
        for preset in report["export_presets"]:
            lines.append(
                f"- {preset['name'] or '(unnamed)'}: "
                f"{preset['platform'] or '(unknown)'} -> "
                f"{preset['export_path'] or '(no path)'}"
            )
            for key, value in preset.get("public_options", {}).items():
                lines.append(f"  - {key}: {value}")
    else:
        lines.append("- (none)")

    lines.extend(["", "## Host tools", ""])
    for name, present in report["host_tools"].items():
        lines.append(f"- {name}: {'yes' if present else 'no'}")

    lines.extend(["", "## Warnings", ""])
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
    except (FileNotFoundError, configparser.Error, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(json.dumps(report, ensure_ascii=False, indent=2) if args.json else markdown(report))
    return 1 if args.strict and warnings else 0


if __name__ == "__main__":
    raise SystemExit(main())
