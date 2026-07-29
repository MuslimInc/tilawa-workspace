#!/usr/bin/env python3
"""Transform injectable injection.config.dart into feature GetIt Di modules.

Reads apps/tilawa/lib/core/di/injection.config.dart and emits:
  - features/<feature>/di/<feature>_di.dart (or core/di/core_services_di.dart)
  - core/di/app_di_orchestrator.dart that calls modules in config order

Skips registrations that delegate to @module instances (handled by manual
module.register). Resolves _iNNN.Type aliases to real imports.
"""

from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "apps/tilawa/lib/core/di/injection.config.dart"
OUT_DIR = ROOT / "apps/tilawa/lib"

IMPORT_RE = re.compile(
    r"import '([^']+)'(?:\s+as (_i\d+))?;",
)
# Multi-line import: import 'x'\n    as _iN;
IMPORT_ML_RE = re.compile(
    r"import '([^']+)'\s+as (_i\d+);",
    re.MULTILINE,
)

REG_START_RE = re.compile(
    r"gh\.(factory|singleton|lazySingleton)<([^>]+)>\(\s*",
)

MODULE_VAR_RE = re.compile(
    r"\b(externalDependenciesModule|appReviewModule|appReviewPolicyModule|"
    r"downloadsModule|homeScreenModule|recitationPracticeModule|"
    r"adhanModule|settingsModule)\b"
)

TYPE_REF_RE = re.compile(r"(_i\d+)\.([A-Za-z_][A-Za-z0-9_]*)")


def feature_key(uri: str) -> str:
    if "/features/" in uri:
        rest = uri.split("/features/", 1)[1]
        return rest.split("/", 1)[0]
    if "/core/" in uri:
        return "core"
    if "/shared/" in uri:
        return "shared"
    return "misc"


def module_class_name(key: str) -> str:
    parts = key.split("_")
    return "".join(p.title() for p in parts) + "Di"


def parse_imports(text: str) -> dict[str, str]:
    aliases: dict[str, str] = {}
    for m in IMPORT_ML_RE.finditer(text):
        uri, alias = m.group(1), m.group(2)
        aliases[alias] = uri
    # bare imports without alias (rare in this file)
    for m in IMPORT_RE.finditer(text):
        uri, alias = m.group(1), m.group(2)
        if alias:
            aliases[alias] = uri
    return aliases


def extract_init_body(text: str) -> str:
    start = text.index("Future<_i174.GetIt> init(")
    # find opening brace of method
    brace = text.index("{", start)
    # find matching close before the module stub classes
    end_marker = text.index("\nclass _$ExternalDependenciesModule")
    body = text[brace + 1 : end_marker]
    # strip trailing `return this;\n  }\n}`
    body = re.sub(r"return this;\s*\}\s*$", "", body, flags=re.DOTALL)
    return body


def split_registrations(body: str) -> list[tuple[str, str, str]]:
    """Return list of (lifecycle, type_expr, factory_body)."""
    results: list[tuple[str, str, str]] = []
    i = 0
    while True:
        m = REG_START_RE.search(body, i)
        if not m:
            break
        lifecycle, type_expr = m.group(1), m.group(2).strip()
        # find factory arg starting at m.end()
        pos = m.end()
        # skip whitespace; expect () => ... or (args) =>
        # Find matching closing paren for gh.xxx<>( ... );
        depth = 1  # already inside outer (
        j = pos
        while j < len(body) and depth > 0:
            c = body[j]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            j += 1
        factory_src = body[pos : j - 1].strip()
        # consume trailing semicolon
        if j < len(body) and body[j] == ";":
            j += 1
        results.append((lifecycle, type_expr, factory_src))
        i = j
    return results


def resolve_type(type_expr: str, aliases: dict[str, str]) -> tuple[str, str | None]:
    """Return (TypeName, import_uri or None for dart core/builtin)."""
    type_expr = type_expr.strip()
    # List<_i87.MediaItem>
    if type_expr.startswith("List<"):
        inner = type_expr[5:-1]
        name, uri = resolve_type(inner, aliases)
        return f"List<{name}>", uri
    m = TYPE_REF_RE.fullmatch(type_expr)
    if m:
        alias, name = m.group(1), m.group(2)
        return name, aliases.get(alias)
    # bare type (unlikely)
    return type_expr, None


def rewrite_factory(factory_src: str, aliases: dict[str, str]) -> str:
    """Rewrite factory body: strip prefixes, gh<T>() -> getIt<T>()."""

    def repl_type(m: re.Match[str]) -> str:
        return m.group(2)

    # Replace _iN.Name with Name
    out = TYPE_REF_RE.sub(repl_type, factory_src)
    # Replace gh<Foo>(...) with getIt<Foo>()
    out = re.sub(r"\bgh<", "getIt<", out)
    # Module method calls should not appear (filtered), but if any remain leave them
    return out


def lifecycle_to_method(lifecycle: str) -> str:
    return {
        "factory": "registerFactoryIfAbsent",
        "singleton": "registerSingletonFactoryIfAbsent",
        "lazySingleton": "registerLazySingletonIfAbsent",
    }[lifecycle]


def main() -> None:
    text = CONFIG.read_text()
    aliases = parse_imports(text)
    body = extract_init_body(text)
    regs = split_registrations(body)

    # Group by feature; preserve order within and overall order list
    by_feature: dict[str, list[tuple[str, str, str, str | None]]] = defaultdict(list)
    order: list[str] = []

    skipped_module = 0
    for lifecycle, type_expr, factory_src in regs:
        if MODULE_VAR_RE.search(factory_src):
            skipped_module += 1
            continue
        if "TilawaCorePackageModule" in factory_src:
            skipped_module += 1
            continue
        type_name, uri = resolve_type(type_expr, aliases)
        key = feature_key(uri or "")
        if key not in by_feature:
            order.append(key)
        factory = rewrite_factory(factory_src, aliases)
        by_feature[key].append((lifecycle, type_name, factory, uri))

    # Also collect all uris needed per feature for imports
    print(f"Parsed {len(regs)} regs, skipped {skipped_module} module-backed, "
          f"{sum(len(v) for v in by_feature.values())} to emit across {len(by_feature)} features")

    # Need registerSingleton with factory - get_it has registerSingletonAsync
    # or registerLazySingleton. For true singleton eager: registerSingleton(instance)
    # injectable's gh.singleton(() => x) is EAGER factory. get_it:
    #   registerSingleton<T>(T instance) OR
    #   registerLazySingleton - lazy
    # For eager singleton from factory: getIt.registerSingleton<T>(factory())
    # But that constructs immediately which may need deps already constructed.
    # injectable GetItHelper.singleton registers as lazySingleton by default in some versions
    # Actually injectable's gh.singleton uses getIt.registerSingleton with a factory that runs immediately...
    # Looking at injectable source: singleton registers with registerSingleton(factory(), ...)
    # NO - GetItHelper.singleton does:
    #   getIt.registerSingleton(instanceFactory(), instanceName: ..., signalsReady: ...)
    # which calls factory immediately!
    # That would break if deps aren't ready. But injectable registers in order so deps exist.
    # For our IfAbsent helpers we only have registerSingletonOnce(instance).
    # Safer: map @singleton -> registerLazySingletonIfAbsent to preserve "one instance"
    # semantics without eager construction order issues. Behavior change: deferred init.
    # Plan says preserve singleton lifecycle. Eager singleton:
    #   if (!isRegistered) registerSingleton(factory())
    # We'll add registerEagerSingletonIfAbsent helper.

    # Rebuild with original factory texts for import collection
    by_feature_raw: dict[str, list[tuple[str, str, str, str, str | None]]] = defaultdict(
        list
    )
    order = []
    for lifecycle, type_expr, factory_src in regs:
        if MODULE_VAR_RE.search(factory_src):
            continue
        if "TilawaCorePackageModule" in factory_src:
            continue
        type_name, uri = resolve_type(type_expr, aliases)
        key = feature_key(uri or "misc")
        if key not in by_feature_raw:
            order.append(key)
        by_feature_raw[key].append((lifecycle, type_name, type_expr, factory_src, uri))

    emitted_paths: list[tuple[str, str, str]] = []

    for key in order:
        items = by_feature_raw[key]
        class_name = module_class_name(key)
        needed_aliases: set[str] = set()
        for _, _, type_expr, factory_src, _ in items:
            for m in TYPE_REF_RE.finditer(type_expr):
                needed_aliases.add(m.group(1))
            for m in TYPE_REF_RE.finditer(factory_src):
                needed_aliases.add(m.group(1))

        imports = {
            "package:get_it/get_it.dart",
            "package:tilawa/core/di/get_it_idempotent.dart",
        }
        for alias in sorted(needed_aliases):
            uri = aliases.get(alias)
            if uri and uri.startswith("package:"):
                imports.add(uri)

        lines: list[str] = []
        for imp in sorted(imports):
            lines.append(f"import '{imp}';")
        lines.append("")
        lines.append(f"/// Manual GetIt registrations for `{key}`.")
        lines.append(f"class {class_name} {{")
        lines.append(f"  {class_name}._();")
        lines.append("")
        lines.append("  static void register(GetIt getIt) {")
        for lifecycle, type_name, _, factory_src, _ in items:
            factory = rewrite_factory(factory_src, aliases)
            method = {
                "factory": "registerFactoryIfAbsent",
                "lazySingleton": "registerLazySingletonIfAbsent",
                "singleton": "registerEagerSingletonIfAbsent",
            }[lifecycle]
            lines.append(f"    getIt.{method}<{type_name}>(")
            fact_lines = factory.split("\n")
            if len(fact_lines) == 1:
                lines.append(f"      {fact_lines[0]},")
            else:
                lines.append(f"      {fact_lines[0]}")
                for fl in fact_lines[1:]:
                    lines.append(f"    {fl}" if fl.strip() else fl)
                if not fact_lines[-1].rstrip().endswith(","):
                    lines.append(",")
            lines.append("    );")
        lines.append("  }")
        lines.append("}")
        lines.append("")

        if key == "core":
            rel = Path("core/di/core_services_di.dart")
        elif key == "shared":
            rel = Path("shared/di/shared_di.dart")
        elif key == "misc":
            rel = Path("core/di/misc_di.dart")
        else:
            rel = Path(f"features/{key}/di/{key}_di.dart")

        out_path = OUT_DIR / rel
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text("\n".join(lines))
        package_uri = f"package:tilawa/{rel.as_posix()}"
        emitted_paths.append((key, class_name, package_uri))
        print(f"  wrote {rel} ({len(items)} regs)")

    # Orchestrator
    orch_lines = [
        "import 'package:get_it/get_it.dart';",
        "import 'package:tilawa_core/di/tilawa_core_di.dart';",
        "import 'package:tilawa/core/di/adhan_module.dart';",
        "import 'package:tilawa/core/di/external_dependencies_module.dart';",
        "import 'package:tilawa/features/app_review/di/app_review_module.dart';",
        "import 'package:tilawa/features/app_review/di/app_review_policy_module.dart';",
        "import 'package:tilawa/features/downloads/di/downloads_module.dart';",
        "import 'package:tilawa/features/home/di/home_screen_module.dart';",
        "import 'package:tilawa/features/recitation_practice/di/recitation_practice_module.dart';",
        "import 'package:tilawa/features/settings/di/settings_module.dart';",
    ]
    for key, class_name, uri in emitted_paths:
        orch_lines.append(f"import '{uri}';")
    orch_lines += [
        "",
        "/// Registers the former injectable graph via explicit feature modules.",
        "void registerManualDependencyGraph(GetIt getIt) {",
        "  TilawaCoreDi.register(getIt);",
        "  ExternalDependenciesModule.register(getIt);",
        "  AppReviewModule.register(getIt);",
        "  AppReviewPolicyModule.register(getIt);",
        "  DownloadsModule.register(getIt);",
        "  HomeScreenModule.register(getIt);",
        "  RecitationPracticeModule.register(getIt);",
        "  AdhanModule.register(getIt);",
        "  SettingsModule.register(getIt);",
    ]
    for key, class_name, _ in emitted_paths:
        orch_lines.append(f"  {class_name}.register(getIt);")
    orch_lines += [
        "}",
        "",
    ]
    orch_path = OUT_DIR / "core/di/app_di_orchestrator.dart"
    orch_path.write_text("\n".join(orch_lines))
    print(f"wrote {orch_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
