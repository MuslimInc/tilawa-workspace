<!--
Sync Impact Report:
- Version change: [INITIAL] -> 1.0.0
- List of modified principles:
  - [PRINCIPLE_1_NAME] -> I. Strict Layered Clean Architecture
  - [PRINCIPLE_2_NAME] -> II. Reactive State Management & Routing
  - [PRINCIPLE_3_NAME] -> III. Atomic Design & Adaptive UI Kit
  - [PRINCIPLE_4_NAME] -> IV. Performance-First Development (Anti-Jank)
  - [PRINCIPLE_5_NAME] -> V. High Observability & Testability
- Added sections:
  - Development Quality Standards
  - Project Organization & Refactoring
- Templates requiring updates:
  - plan-template.md: ✅ Aligned
  - spec-template.md: ✅ Aligned
  - tasks-template.md: ✅ Aligned
- Follow-up TODOs: None
-->

# Tilawa Workspace Constitution

## Core Principles

### I. Strict Layered Clean Architecture
The project MUST adhere to a clean layered architecture: Presentation, Domain, and Data layers.
- **Layer Boundaries**: Clean boundaries must be maintained between layers to prevent leakage of concerns.
- **Dependency Rule**: Dependencies MUST flow inwards (Presentation -> Domain -> Data). No direct dependency from Presentation to Data layer is allowed.
- **Feature-First**: Organize code by feature folders when appropriate to keep related files (UI, BLoC, Models) together.

### II. Reactive State Management & Routing
State management and navigation MUST follow predictable, reactive patterns.
- **BLoC**: BLoC (Business Logic Component) MUST be used for handling app state and business logic, ensuring a clear separation from UI.
- **GoRouter**: GoRouter MUST be used for declarative, deep-linkable routing.
- **Reactive UI**: The UI should reactively update based on BLoC states, avoiding manual state manipulation in widgets.

### III. Atomic Design & Adaptive UI Kit
UI development MUST focus on reusability, consistency, and responsiveness.
- **Atomic Design**: Components MUST be built following Atomic Design principles (Atoms, Molecules, Organisms).
- **Shared UI Kit**: Reusable UI components MUST be centralized in a shared UI Kit to ensure visual consistency.
- **Adaptive UI**: UI MUST be responsive and adaptive to different screen sizes and platforms (mobile, web, desktop).

### IV. Performance-First Development (Anti-Jank)
Performance is a first-class citizen and MUST NOT be an afterthought.
- **Anti-Jank**: Widget building MUST be performance-aware (using `const`, minimizing rebuilds) to ensure low jank and 60+ FPS.
- **No Magic Numbers**: Avoid magic numbers and hard-coded values; use design tokens, constants, and theme extensions for dimensions and colors.
- **Optimization**: Expensive operations MUST be moved out of the build methods.

### V. High Observability & Testability
The codebase MUST be easy to monitor, debug, and verify.
- **Clear Logging**: Implement structured logging that includes widget and feature names for better traceability.
- **Testing Discipline**: Unit tests MUST be written for domain logic, and widget tests MUST be written for critical UI components.
- **Maintainability**: Code must be written with readability and maintainability as top priorities.

## Development Quality Standards

The following standards apply to all development activities:
- **Naming Conventions**: Use clear, descriptive, and consistent naming for all variables, functions, classes, and files (PascalCase for classes, camelCase for members, snake_case for files).
- **SOLID Principles**: Apply SOLID principles strictly to ensure classes are focused, extensible, and maintainable.
- **Avoid Hard-coding**: All strings, dimensions, and colors MUST be managed through appropriate theme, constants, or localization files.

## Project Organization & Refactoring

Guidelines for code structure and evolution:
- **Layered Structure**: Follow the `lib/features/[feature_name]/[presentation|domain|data]` structure.
- **Safe Refactoring**: Before any major refactoring, ensure adequate test coverage exists. Refactor in small, verifiable steps.
- **Documentation**: Maintain documentation integrity, including READMEs, API comments (`///`), and complex logic explanations.

## Governance

This Constitution is the supreme governing document for Tilawa Workspace.
- **Compliance**: All Pull Requests and architectural decisions MUST be reviewed against these principles.
- **Amendments**: Changes to the Constitution require a version bump (MAJOR.MINOR.PATCH) and documented rationale.
- **Conflict Resolution**: In case of conflict between speed and quality, quality (as defined by these principles) should generally prevail unless explicitly waived for an MVP.

**Version**: 1.0.0 | **Ratified**: 2026-04-23 | **Last Amended**: 2026-04-23
