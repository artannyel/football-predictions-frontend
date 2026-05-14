# Project: Football Predictions

A Flutter application for managing and participating in football prediction leagues. The project features a modular architecture, real-time updates via Firebase, and a rich user interface for tracking matches, rankings, and individual predictions.

## Architecture

The project follows a feature-based modular architecture, separating concerns into `core` and `features` layers.

### Core Layer (`lib/core/`)
Contains cross-cutting concerns and shared infrastructure:
- **auth/**: Authentication state management via `AuthNotifier`.
- **navigation/**: Routing configuration using `GoRouter`.
- **presentation/widgets/**: Reusable UI components (e.g., `AppNetworkImage`, `LoadingWidget`).
- **providers/**: App-wide state providers (e.g., `ThemeProvider`).
- **utils/**: Utilities and platform-specific stubs (e.g., OneSignal, File Saver).

### Features Layer (`lib/features/`)
Each directory represents a self-contained functional module:
- **auth/**: User authentication flows (Login, Signup, Profile management).
- **home/**: Dashboard for leagues, league details, and league-specific chat.
- **competitions/**: Browsing available football competitions.
- **matches/**: Match listings and details for specific competitions.
- **predictions/**: Creating and viewing user predictions.
- **ranking/**: Leaderboards for leagues and competitions.
- **admin/**: Internal tools for managing badges, logs, and matches (accessed via the Admin flavor).

## Key Technologies

- **Framework**: Flutter
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio) (wrapped in `DioClient`)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore)
- **Push Notifications**: [OneSignal](https://onesignal.com/)
- **Images**: [Cached Network Image](https://pub.dev/packages/cached_network_image), [Flutter SVG](https://pub.dev/packages/flutter_svg)

## Development Workflows

### Prerequisites
- Flutter SDK (Check `pubspec.yaml` for minimum version)
- Firebase Project setup

### Environment Flavors
The project uses multiple entry points for different environments:
- **Development**: `lib/main_dev.dart`
- **Production**: `lib/main_prod.dart`
- **Admin**: `lib/main_admin.dart`

### Common Commands

| Task | Command |
| :--- | :--- |
| **Run (Dev)** | `flutter run -t lib/main_dev.dart` |
| **Run (Prod)** | `flutter run -t lib/main_prod.dart` |
| **Run (Admin)** | `flutter run -t lib/main_admin.dart` |
| **Analyze** | `flutter analyze` |
| **Test** | `flutter test` |
| **Build Web** | `flutter build web -t lib/main_prod.dart` |
| **Build Android** | `flutter build apk -t lib/main_prod.dart` |

## Coding Standards & Conventions

- **Linting**: Adheres to `package:flutter_lints/flutter.yaml`.
- **Formatting**: Use standard `flutter format`.
- **Naming**: Use `lower_snake_case` for files and `UpperCamelCase` for classes.
- **Structure**: Follow the `data/presentation` split within feature folders.
- **Routing**: Define all routes in `lib/core/navigation/app_router.dart`.
- **Security**: Never commit sensitive environment variables or Firebase configuration secrets directly. Use `--dart-define` for secrets like `ONESIGNAL_APP_ID`.
