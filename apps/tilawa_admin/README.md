# Tilawa Admin

Angular admin panel for Tilawa. Supports **English** and **Arabic** with runtime language switching.

## Localization

Translations use the [Application Resource Bundle (ARB)](https://github.com/google/app-resource-bundle) format — same convention as the Flutter apps in this monorepo.

- Source files: `l10n/app_en.arb` and `l10n/app_ar.arb`
- Runtime load: `I18nService` fetches `/l10n/app_{lang}.arb` at startup and on language change
- Message IDs: `section_subkey` (letters, numbers, underscores only — no dots)
- Template: `{{ 'sidebar_wallets' | t }}`
- Interpolation: `{{ 'disputes_detailTitle' | t: { id: item.id } }}` (ARB `{param}` syntax; legacy `{{param}}` still works in `t()`)
- Status enums: `{{ item.status | statusLabel }}` (maps `status_*` keys)
- Language switcher: header (admin layout) and login screen
- Preference key: `localStorage` → `tilawa-admin-lang` (`en` | `ar`)
- Default: browser language if Arabic, otherwise English
- RTL: sets `document.documentElement.dir` and `lang` when Arabic is active

### Adding strings

1. Add the message ID and English text to `l10n/app_en.arb`
2. Add the same message ID and Arabic text to `l10n/app_ar.arb`
3. For placeholders, use `{name}` in the string and add an `@messageId` metadata block:

```json
"disputes_detailTitle": "Dispute {id}",
"@disputes_detailTitle": {
  "description": "Dispute detail page title",
  "placeholders": {
    "id": { "type": "String", "example": "abc123" }
  }
}
```

4. Import `TranslatePipe` in the standalone component and use `| t` in the template.

### Migrating from nested JSON

If you have legacy nested JSON, run the one-time helper:

```bash
node scripts/flatten-json-to-arb.mjs --input path/to/en.json --locale en --output l10n/app_en.arb
```

Core services: `src/app/core/i18n/i18n.service.ts`, `translate.pipe.ts`, `status-label.pipe.ts`.

## Development server

To start a local development server, run:

```bash
ng serve
```

Once the server is running, open your browser and navigate to `http://localhost:4200/`. The application will automatically reload whenever you modify any of the source files.

## Code scaffolding

Angular CLI includes powerful code scaffolding tools. To generate a new component, run:

```bash
ng generate component component-name
```

For a complete list of available schematics (such as `components`, `directives`, or `pipes`), run:

```bash
ng generate --help
```

## Building

To build the project run:

```bash
ng build
```

This will compile your project and store the build artifacts in
`dist/tilawa-admin/browser/`. By default, the production build optimizes your
application for performance and speed.

## Deploy (Firebase Hosting)

Admin site target: `hosting:admin` → Firebase site `tilawa-admin` (project
`quran-playera-app`). Requires the site to exist in Firebase Console and hosting
targets applied (see repo-root `.firebaserc`).

From repo root:

```bash
melos run admin:deploy
```

From this directory:

```bash
npm run deploy
```

Legal pages (`tilawa.app`) use a separate target: `firebase deploy --only hosting:legal`.

## Running unit tests

To execute unit tests with the [Vitest](https://vitest.dev/) test runner, use the following command:

```bash
ng test
```

## Running end-to-end tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

Angular CLI does not come with an end-to-end testing framework by default. You can choose one that suits your needs.

## Additional Resources

For more information on using the Angular CLI, including detailed command references, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.
