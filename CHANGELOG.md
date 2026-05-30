## 1.0.4

- Updated README: added dedicated Custom Icons section covering all four icon input methods (`iconWidget`, `iconAsset`, `iconNetwork`, `iconProvider`) with usage examples.
- Updated README: added `★ Asset / network icons` and `★ SVG / Lottie icon slot` rows to the feature comparison table.
- Updated README: install snippet now references `^1.0.3`.

## 1.0.3

- **Fixed:** Notifications never rendered — the stream bridge was split across two files (`awesome_snackbar.dart` had `emit()`, `awesome_widget.dart` had `stream`) and they never connected. Replaced with a single shared `AwesomeController` singleton.
- **Fixed:** `dismissById()` had no effect — `registerActive` was never called, so the dismiss callback map was always empty.
- **Fixed:** `AwesomeDismissDirection.any` was incorrectly mapped to `DismissDirection.none`, silently disabling swipe-to-dismiss entirely.
- **Added:** Four icon input variants in `AwesomeOptions` — `iconWidget` (any Flutter widget including SVG and Lottie), `iconAsset` (local asset path), `iconNetwork` (remote URL with loading indicator), and `iconProvider` (any `ImageProvider`). All fall back gracefully to the default type icon on error.
- **Removed:** The previous `icon: Widget?` field, superseded by the four typed icon fields above.

## 1.0.2

- Fixed pubspec description length for pub.dev score compliance.
- Improved YAML formatting and field ordering.

## 1.0.1

- Patch release: minor documentation corrections.

## 1.0.0

- Initial release.
- Zero external dependencies — pure Flutter.
- 9 built-in animations: slide, fade, scale, elastic, bounce, rotation, iOS, flip, path.
- Priority queue system (normal / high / critical).
- Future tracking API with dynamic success/error messages.
- Haptic feedback via Flutter's built-in `HapticFeedback`.
- Glassmorphism via `dart:ui` `ImageFilter.blur`.
- Notification history with filtering by type and tag.
- Grouped notifications with `dismissGroup`.
- Scheduling with `schedule` / `cancelScheduled`.
- Tap-to-route navigation support.
- Duplicate prevention via `key`.
- Context, String, and Future extension methods.
- Full accessibility label support.
- Dark mode colour palettes for all notification types.
- Supports Android, iOS, Web, Windows, macOS, Linux.