# Marionette MCP (debug-only AI runtime testing)

MeMuslim / Tilawa integrates [Marionette](https://pub.dev/packages/marionette_flutter)
so AI coding agents can inspect and drive a **debug** Flutter session via MCP.

> **Warning — debug only.** `MarionetteBinding` is initialized only when
> `kDebugMode` is true (and not under `flutter test`). Do **not** enable or
> expose Marionette in profile or release builds. Production keeps the existing
> `SentryWidgetsFlutterBinding` path.

## Install the MCP bridge

```bash
dart pub global activate marionette_mcp
```

Ensure `~/.pub-cache/bin` is on your `PATH` so `marionette_mcp` resolves.

## Configure the AI tool (Cursor)

Project config already includes Marionette in [`.cursor/mcp.json`](../../.cursor/mcp.json):

```json
{
  "mcpServers": {
    "marionette": {
      "command": "marionette_mcp",
      "args": []
    }
  }
}
```

Reload MCP servers in Cursor after install. Global alternative: add the same
block to `~/.cursor/mcp.json`.

## Run MeMuslim in debug mode

From the workspace root (FVM / Flutter 3.44+):

```bash
cd apps/tilawa
flutter run --debug -d <device_id>
```

Use a connected emulator, simulator, or desktop device. Wait until Home (or
onboarding) is interactive.

## Obtain the VM Service URI

In the `flutter run` console, find the DevTools / VM service line, for example:

```text
The Flutter DevTools debugger and profiler ... is available at:
http://127.0.0.1:9101?uri=ws://127.0.0.1:9101/ws
```

Copy the `ws://…` URI (here `ws://127.0.0.1:9101/ws`). Pasting it into the
agent is the most reliable connection flow.

## Example agent prompts

**Connect and list controls:**

> Connect to the Flutter app at `ws://127.0.0.1:9101/ws`, then call
> `get_interactive_elements` and summarize the bottom navigation tabs.

**Smoke navigate tabs:**

> Using Marionette, tap identifiers `home_tab`, `quran_index_nav`,
> `reciters_tab`, and `settings_tab`. After each tap, take a screenshot and
> confirm the destination loaded without exceptions in `get_logs`.

**Last Read / Quran:**

> From Home, tap `home_last_read` (or `home_quran_resume`). If the Surah index
> is open, tap `surah_index_1`, then go back. Report overflow errors,
> unresponsive controls, and runtime exceptions.

## Semantic identifiers (stable targets)

| Identifier | Surface |
| --- | --- |
| `home_tab` / `quran_index_nav` / `reciters_tab` / `settings_tab` | Phone bottom nav |
| `home_last_read` | Home primary Quran / Last Read tile |
| `home_quran_resume` | Home Quran resume card |
| `home_quick_quran` / `home_quick_reciters` | Home Quran entry grid |
| `home_athkar` | Home Athkar primary tile |
| `home_next_prayer` | Home next-prayer hero |
| `surah_index_<n>` | Surah row in Quran index |
| `onboarding_primary` / `onboarding_back` | Onboarding footer |
| `settings_theme` / `settings_language` | Settings theme & language tiles |

## CLI vs MCP selectors

- **MCP tools** (Cursor `marionette` server): `tap` accepts `identifier` (Semantics), `key`, `text`, and coordinates.
- **`marionette` CLI 0.6.0**: `tap` accepts `--key`, `--text`, `--type`, `--x/--y` only — not `--identifier`. Prefer `tap --text '…'` or coordinates from `get-interactive-elements` bounds when using the CLI.


Audio player controls and many settings tiles already expose human-readable
`Semantics` labels via the design system (`TilawaInteractiveSurface`,
`TilawaButton`, `TilawaSettingsTile`).

## App wiring (for maintainers)

- Dependency: `marionette_flutter: 0.6.0` in `apps/tilawa/pubspec.yaml`
  (**regular** dependency — imported at compile time).
- Binding: `ensureTilawaWidgetsBinding()` in `lib/main.dart` **before**
  `SentryFlutter.init` (required to avoid splash hang with Sentry).
- Helper: `lib/core/debug/marionette_binding.dart` — debug-only
  `MarionetteBinding` + design-system `isInteractiveWidget` /
  `extractText` + `PrintLogCollector` bridged from `logger`.
- Bootstrap / background isolates still call
  `WidgetsFlutterBinding.ensureInitialized()`; that reuses the existing
  binding and must not run before Marionette in the main isolate debug path.

Upstream docs: [Flutter setup](https://github.com/leancodepl/marionette_mcp/blob/main/docs/flutter-setup.md),
[MCP tools](https://github.com/leancodepl/marionette_mcp/blob/main/docs/mcp-tools.md).
