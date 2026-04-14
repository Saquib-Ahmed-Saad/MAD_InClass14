# Fit.io Architecture

## Overview

Fit.io follows a lightweight layered architecture to keep UI logic simple, data access isolated, and future scaling straightforward.

Layers:

1. Presentation Layer (`screens/`, `widgets/`)
2. Application Layer (`app_controller.dart`, `services/`)
3. Data Layer (`repositories/`, `data/`, `models/`)

## Why This Architecture

- Separation of concerns: UI does not execute raw SQL.
- Maintainability: SQLite and SharedPreferences logic is centralized.
- Testability: Business calculations (streaks, weekly counts) are in services.
- Simplicity: Fits project scope and deadline without overengineering.

## Component Responsibilities

### Presentation Layer

- `SplashScreen`: branding and startup transition
- `HomeShellScreen`: bottom navigation and screen switching
- `DashboardScreen`: habit overview and daily completion actions
- `CreateEditHabitScreen`: form input, validation, create/update actions
- `HabitDetailsScreen`: single habit details, history, edit/delete
- `ProgressScreen`: chart and aggregate statistics
- `SettingsScreen`: user preferences and reset action
- Reusable widgets:
  - `HabitTile`
  - `WeeklyChart`

### Application Layer

- `AppController`
  - global app settings state
  - theme mode updates
  - notifications preference updates
  - exposes repository to screens

- `SettingsService`
  - reads/writes SharedPreferences

- `HabitMetricsService`
  - computes current streak
  - computes 7-day completion totals

### Data Layer

- `FitioDatabase`
  - creates and opens SQLite database
  - defines `habits` and `habit_logs` schema

- `HabitRepository`
  - all CRUD operations for habits
  - daily completion logging
  - reads logs for details and analytics
  - reset operation for full local wipe

- Models:
  - `Habit`
  - `HabitLog`
  - `DashboardSummary`

## Data Flow

1. User interacts with a screen (for example, presses Save Habit).
2. Screen validates input and calls `HabitRepository`.
3. Repository writes to SQLite via `FitioDatabase`.
4. Screen reloads repository data and updates UI state.
5. Metrics are derived in `HabitMetricsService` from log data.

## State Management Decision

This project uses local `StatefulWidget` state for page data and a small `ChangeNotifier` (`AppController`) for global settings.

Rationale:

- Keeps undergraduate scope practical.
- Avoids unnecessary complexity while still separating global state concerns.
- Supports clear evolution to Provider/Riverpod later if needed.

## Offline-First Strategy

- All core business data is stored in SQLite.
- Preferences are stored in SharedPreferences.
- No network services are required for core app functionality.

## Validation and Error Handling

- Form validation prevents empty habit name submissions.
- Confirmation dialogs protect destructive actions (delete/reset).
- Empty-state UI handles no habits and no logs scenarios.
- UI feedback is shown using snackbars and loading indicators.

## Scalability Notes

Potential next steps with minimal refactor:

- Add repository interfaces for dependency injection.
- Add use-case classes for operations.
- Add notification scheduler service.
- Add export/import service for backup restore workflows.
