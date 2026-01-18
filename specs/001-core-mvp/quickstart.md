# Quickstart: Core MVP

## Prerequisites
- Flutter SDK (latest stable)
- VS Code or Android Studio with Flutter plugins

## Running the App

1.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Generate Code** (Drift, Riverpod, Freezed):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

3.  **Run Development Build**:
    ```bash
    flutter run
    ```

## Testing

### Unit Tests (Logic)
*Note: Unit tests are yet to be implemented.*
```bash
flutter test
```

## Key Commands
- **Lint Check**: `flutter analyze`
- **Fix Lints**: `dart fix --apply`
- **Re-gen Translations**: `flutter gen-l10n`