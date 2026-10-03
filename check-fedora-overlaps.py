#!/usr/bin/env python3
"""List Terra RPM names that also exist in Fedora Rawhide."""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RAWHIDE_REPO = (
    "https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/"
    "Everything/{arch}/os/"
)
SUBREPO_LABEL = re.compile(r"^\s*subrepo\s*=\s*\"[^\"]+\"\s*(?:#.*)?$", re.MULTILINE)


def query_fedora_names(dnf, arch):
    repo_id = "fedora-rawhide-overlap-check"
    repo_url = RAWHIDE_REPO.format(arch=arch)

    with tempfile.TemporaryDirectory(prefix="terra-fedora-overlaps-") as temp_dir:
        temp = Path(temp_dir)
        command = [
            dnf,
            "--quiet",
            f"--setopt=cachedir={temp / 'cache'}",
            f"--setopt=persistdir={temp / 'persist'}",
            f"--setopt=logdir={temp / 'log'}",
            f"--repofrompath={repo_id},{repo_url}",
            f"--repo={repo_id}",
            f"--forcearch={arch}",
            "repoquery",
            "--queryformat=%{name}\\n",
            "*",
        ]
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            timeout=300,
        )

    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(detail or f"{dnf} repoquery failed")

    return {name.strip() for name in result.stdout.splitlines() if name.strip()}


def terra_package_names(spec_path, rpmspec):
    names = set()
    parse_failed = False

    if rpmspec:
        try:
            result = subprocess.run(
                [rpmspec, "-q", "--qf", "%{name}\\n", str(spec_path)],
                capture_output=True,
                text=True,
                check=False,
                timeout=30,
            )
            names.update(
                name.strip()
                for name in result.stdout.splitlines()
                if name.strip() and "%" not in name
            )
            parse_failed = result.returncode != 0
        except (OSError, subprocess.TimeoutExpired):
            parse_failed = True

    if not names or parse_failed:
        try:
            text = spec_path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            text = ""
        match = re.search(r"^Name:\s*([^\s#]+)", text, re.MULTILINE | re.IGNORECASE)
        if match and "%" not in match.group(1):
            names.add(match.group(1))

    return names, parse_failed


def is_subrepo_package(spec_path):
    anda_config = spec_path.parent / "anda.hcl"
    try:
        config = anda_config.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        raise RuntimeError(f"could not read {anda_config}: {error}") from error
    return SUBREPO_LABEL.search(config) is not None


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Find exact RPM package-name matches between Terra spec files and "
            "Fedora Rawhide. This reports review candidates; it does not remove packages."
        )
    )
    parser.add_argument(
        "--spec-root",
        type=Path,
        default=Path("anda"),
        help="directory containing Terra .spec files (default: ./anda)",
    )
    parser.add_argument(
        "--arch",
        default="x86_64",
        help="Fedora Rawhide architecture to check (default: x86_64)",
    )
    args = parser.parse_args()

    spec_root = args.spec_root.resolve()
    if not spec_root.is_dir():
        parser.error(f"spec directory does not exist: {spec_root}")

    specs = sorted(spec_root.rglob("*.spec"))
    if not specs:
        parser.error(f"no .spec files found under {spec_root}")

    dnf = shutil.which("dnf")
    if not dnf:
        print("error: dnf (DNF5) is required", file=sys.stderr)
        return 1

    try:
        fedora_names = query_fedora_names(dnf, args.arch)
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"error: could not query Fedora Rawhide: {error}", file=sys.stderr)
        return 1

    rpmspec = shutil.which("rpmspec")
    try:
        main_repo_specs = [spec for spec in specs if not is_subrepo_package(spec)]
    except RuntimeError as error:
        print(
            f"error: could not inspect subrepository labels: {error}", file=sys.stderr
        )
        return 1
    excluded_subrepo_specs = len(specs) - len(main_repo_specs)
    terra_names = {}
    parse_failures = 0
    for spec in main_repo_specs:
        names, failed = terra_package_names(spec, rpmspec)
        parse_failures += failed
        for name in names:
            terra_names.setdefault(name, set()).add(spec)

    matches = sorted(set(terra_names) & fedora_names)
    matched_projects = {
        spec.parent.relative_to(spec_root).as_posix()
        for name in matches
        for spec in terra_names[name]
    }
    for project in sorted(matched_projects):
        print(project)

    print(
        f"Checked {len(main_repo_specs)} main-repository Terra specs "
        f"(excluded {excluded_subrepo_specs} subrepository specs) against "
        f"{len(fedora_names)} Fedora Rawhide package names; found "
        f"{len(matches)} exact name matches across {len(matched_projects)} "
        "Terra project directories.",
        file=sys.stderr,
    )
    if not rpmspec:
        print(
            "warning: rpmspec is unavailable; only literal Name tags were checked.",
            file=sys.stderr,
        )
    elif parse_failures:
        print(
            f"warning: rpmspec could not parse {parse_failures} specs; literal Name "
            "tags were used as a fallback where possible.",
            file=sys.stderr,
        )
    print(
        "Review matches before removing anything: names alone do not establish "
        "equivalent versions, contents, or Terra-specific patches.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
