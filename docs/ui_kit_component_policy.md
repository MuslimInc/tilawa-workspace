# UI Kit component enforcement

Product and feature libraries must use the public `tilawa_ui_kit.dart` API
when the UI Kit has a confirmed equivalent for a Flutter visual component.
The analyzer plugin reports the exact source range and suggests the approved
replacement. It resolves constructor elements, so prefixes, import combinators,
comments, strings, and similarly named application classes do not create false
positives.

## Scope

The rule applies to Dart files under `lib/` in first-party apps and packages.
Generated files and the vendored `flex_color_scheme` package are excluded. Raw
Flutter components are allowed in `packages/ui_kit/lib`, where the abstractions
are implemented. Layout primitives—including `Row`, `Column`, `Padding`,
`Stack`, `SizedBox`, `Expanded`, `ListView`, and slivers—are not component
policy violations.

Product code must import `package:tilawa_ui_kit/tilawa_ui_kit.dart`; imports or
exports from `package:tilawa_ui_kit/src/` are rejected outside UI Kit itself.

## Canonical registry and migration

`packages/tilawa_lints/lib/src/component_policy.dart` is the only component
policy registry. Add a mapping only after checking the UI Kit component against
all production call sites, including constructor options, semantics,
interaction states, responsive behavior, and accessibility. Migrate existing
uses file by file, then add the confirmed mapping so new debt cannot enter.
Count-based baselines are not permitted.

If no genuine equivalent exists, extend the UI Kit at the correct composition
level before adding a mapping. Do not map components merely because their names
or visual appearance are similar.

## Exceptions

Temporary exceptions require both:

1. A unique `// tilawa-ui-exception: ID` marker next to an
   `// ignore: tilawa_ui_component` directive.
2. A matching `UiKitException` registry entry with the exact file suffix,
   component name, concrete reason, and cleanup issue or tracking reference.

Unregistered, duplicate, moved, or incomplete exception markers are errors.
Remove the source marker and registry entry together when the tracking work is
completed.

## Atomic Design audit

Component identity and Atomic Design direction are intentionally separate.
The current UI Kit has `foundation`, `atoms`, `molecules`, and `organisms`.
Observed dependencies include molecules using atoms and organisms using atoms
and molecules, which is the intended direction. Some same-level composition
also exists, and `tilawa_catalog_app_bar.dart` imports the public barrel from
inside the package. Because those patterns need case-by-case classification,
strict atom/molecule/organism dependency enforcement is not enabled yet.

Before enabling it, inventory every cross-level and same-level import, decide
whether foundation is a separate layer, remove barrel self-imports, and approve
the allowed dependency matrix. Implement that check as its own analyzer rule;
do not add layer logic to `tilawa_ui_component`.

## Commands and CI

`dart analyze --fatal-infos` runs the plugin in editors and CI. `melos run
ui:lint` is the focused command, and `melos run lint` is the standard repository
gate. The `analyze-and-test` PR job invokes the standard lint command.

GitHub branch protection must require the `PR Checks / analyze-and-test` status
check. Merely running the workflow is insufficient; repository administrators
must keep that exact check in the protected `master` branch or its ruleset.
