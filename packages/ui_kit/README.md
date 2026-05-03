# Tilawa UI Kit

A premium, design-system-driven UI library for the Tilawa application. Built with Flutter and Material 3, focusing on performance, accessibility, and high-fidelity aesthetics.

## Atoms

### TilawaButton
A highly customizable button component supporting multiple variants, sizes, and states.

#### Variants
- **Primary**: High emphasis, used for the main action on a screen.
- **Secondary**: Medium emphasis, used for secondary actions.
- **Outline**: Medium emphasis with a border, useful for balanced actions.
- **Ghost**: Low emphasis, used for subtle or tertiary actions.
- **Danger**: High emphasis for destructive actions (e.g., Delete).

#### Usage
```dart
TilawaButton(
  text: 'Get Started',
  onPressed: () => print('Tapped!'),
  variant: TilawaButtonVariant.primary,
  size: TilawaButtonSize.medium,
)
```

#### Accessibility
- **Touch Target**: Guaranteed minimum 48x48.
- **States**: Correctly announces "Disabled" or "Loading" states to screen readers.
- **Semantic Labels**: Supports custom labels for complex actions.

### TilawaTextField
A robust text input field with built-in support for validation, password toggling, and clear actions.

#### Features
- **Strict API**: Only design-system-compliant properties are exposed.
- **Password Toggle**: Built-in visibility management with `isPassword: true`.
- **Clear Button**: Integrated clear action with `onClear` callback.
- **Lifecycle Safety**: Manages internal controllers and focus nodes automatically.

#### Usage
```dart
TilawaTextField(
  label: 'Email Address',
  hintText: 'example@email.com',
  onClear: () => print('Cleared!'),
  prefixIcon: Icon(Icons.email_outlined),
  validator: (val) => val!.isEmpty ? 'Required' : null,
)
```

#### Constraints
- `controller` and `initialValue` are mutually exclusive.
- `suffixIcon` cannot be used when `isPassword` or `onClear` is enabled.

### TilawaCard
A versatile container with soft shadows and rounded corners.

### TilawaLoadingIndicator
A smooth, indeterminate progress indicator that matches the app's theme.

## Visual Testing

### Golden Tests
This package uses `alchemist` for visual regression testing.
To update goldens:
```bash
flutter test test/goldens/ --update-goldens
```

### Test Status
**Note**: Full UI Kit suite currently has 2 unrelated pre-existing failures in `tilawa_adaptive_shell_test.dart`:
- `expanded uses extended side rail (LTR)`
- `expanded uses extended side rail (RTL)`

Phase 2B targeted tests and goldens pass. These adaptive shell failures existed before Phase 2B and are unrelated to TextField implementation.

### Previews
Interactive previews are available via the `Widget Previewer` (if configured) or by running the preview app:
```bash
flutter run lib/previews/preview_main.dart # If available
```

## Implementation Guidelines
- **Do**: Use existing design tokens via `AppTheme`.
- **Do**: Ensure all interactive elements have a minimum touch target of 48x48.
- **Don't**: Add haptics directly to atoms; handle feedback at the interaction layer.
- **Don't**: Modify production themes just for test stability; use `useGoogleFontsOverride`.
