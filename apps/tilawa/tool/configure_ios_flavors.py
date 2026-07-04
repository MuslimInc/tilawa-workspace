#!/usr/bin/env python3
"""Add Flutter iOS flavor build configurations to Runner.xcodeproj.

Run from apps/tilawa after `flutter pub get`:
  python3 tool/configure_ios_flavors.py

Idempotent: skips configurations that already exist.
"""

from __future__ import annotations

import re
import uuid
from pathlib import Path

FLAVORS = ("development", "staging", "production")
MODES = ("Debug", "Release", "Profile")
PBXPROJ = Path(__file__).resolve().parents[1] / "ios/Runner.xcodeproj/project.pbxproj"


def new_id() -> str:
    return uuid.uuid4().hex[:24].upper()


def main() -> None:
    text = PBXPROJ.read_text()
    for flavor in FLAVORS:
        for mode in MODES:
            config_name = f"{mode}-{flavor}"
            if f"name = {config_name};" in text:
                continue
            base_mode = mode
            if mode == "Profile":
                project_template = "249021D3217E4FDB00AE95B9"
                runner_template = "249021D4217E4FDB00AE95B9"
                tests_template = "331C808A294A63A400263BE5"
            elif mode == "Release":
                project_template = "97C147041CF9000F007C117D"
                runner_template = "97C147071CF9000F007C117D"
                tests_template = "331C8089294A63A400263BE5"
            else:
                project_template = "97C147031CF9000F007C117D"
                runner_template = "97C147061CF9000F007C117D"
                tests_template = "331C8088294A63A400263BE5"

            xcconfig_name = f"{mode}-{flavor}.xcconfig"
            xcconfig_ref = new_id()
            project_cfg = new_id()
            runner_cfg = new_id()
            tests_cfg = new_id()

            if f"path = Flutter/{xcconfig_name}" not in text:
                file_ref = (
                    f"\t\t{xcconfig_ref} /* {xcconfig_name} */ = "
                    f"{{isa = PBXFileReference; lastKnownFileType = text.xcconfig; "
                    f'name = "{xcconfig_name}"; path = Flutter/{xcconfig_name}; '
                    f"sourceTree = \"<group>\"; }};\n"
                )
                text = text.replace(
                    "/* End PBXFileReference section */",
                    file_ref + "/* End PBXFileReference section */",
                )
                group_insert = f"\t\t\t\t{xcconfig_ref} /* {xcconfig_name} */,\n"
                text = text.replace(
                    "9740EEB31CF90195004384FC /* Generated.xcconfig */,",
                    group_insert
                    + "\t\t\t\t9740EEB31CF90195004384FC /* Generated.xcconfig */,",
                )

            project_block = _extract_block(text, project_template)
            runner_block = _extract_block(text, runner_template)
            tests_block = _extract_block(text, tests_template)

            project_block = _rename_block(project_block, project_cfg, config_name)
            runner_block = _rename_block(runner_block, runner_cfg, config_name)
            if 'baseConfigurationReference = ' in runner_block:
                runner_block = re.sub(
                    r"baseConfigurationReference = [A-F0-9]+ /\* [^*]+ \*/;",
                    f"baseConfigurationReference = {xcconfig_ref} /* {xcconfig_name} */;",
                    runner_block,
                    count=1,
                )
            tests_block = _rename_block(tests_block, tests_cfg, config_name)

            text = text.replace(
                "/* End XCBuildConfiguration section */",
                project_block
                + runner_block
                + tests_block
                + "/* End XCBuildConfiguration section */",
            )

            text = _append_to_config_list(
                text,
                "97C146E91CF9000F007C117D /* Build configuration list for PBXProject \"Runner\" */",
                project_cfg,
                config_name,
            )
            text = _append_to_config_list(
                text,
                "97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget \"Runner\" */",
                runner_cfg,
                config_name,
            )
            text = _append_to_config_list(
                text,
                "331C8087294A63A400263BE5 /* Build configuration list for PBXNativeTarget \"RunnerTests\" */",
                tests_cfg,
                config_name,
            )

    PBXPROJ.write_text(text)
    print(f"Updated {PBXPROJ}")


def _extract_block(text: str, block_id: str) -> str:
    pattern = rf"\t\t{block_id} /\* [^*]+ \*/ = {{[\s\S]*?\n\t\t}};\n"
    match = re.search(pattern, text)
    if not match:
        raise SystemExit(f"Could not find block {block_id}")
    return match.group(0)


def _rename_block(block: str, new_id: str, config_name: str) -> str:
    block = re.sub(
        r"^\t\t[A-F0-9]+",
        f"\t\t{new_id}",
        block,
        count=1,
        flags=re.MULTILINE,
    )
    block = re.sub(r"name = [^;]+;", f"name = {config_name};", block)
    return block


def _append_to_config_list(
    text: str,
    list_comment: str,
    cfg_id: str,
    config_name: str,
) -> str:
    pattern = (
        rf"({re.escape(list_comment)} = {{[\s\S]*?buildConfigurations = \([\s\S]*?)"
        rf"(\t\t\t\);)"
    )

    def repl(match: re.Match[str]) -> str:
        body = match.group(1)
        if f"{cfg_id} /* {config_name} */" in body:
            return match.group(0)
        insertion = f"\t\t\t\t{cfg_id} /* {config_name} */,\n"
        return body + insertion + match.group(2)

    return re.sub(pattern, repl, text, count=1)


if __name__ == "__main__":
    main()
