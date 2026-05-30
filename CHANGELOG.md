## 1.0.5

- **Fixed:** Snackbars were not automatically removed after their timer completed — a double-call race between the auto-dismiss `Timer` and `dismissById()` caused `AnimationController.reverse()` to run twice, silently throwing on the second call and leaving the entry stuck on screen. Added a `_dismissCalled` boolean guard so `_dismiss()` is idempotent.
- **Fixed:** Multiple snackbars appeared simultaneously instead of sequentially — `_processQueue` used `_active.length < maxVisible` (default 3), allowing several items to be promoted at once. Replaced the `_active` map with a single `_current` nullable entry and an `_isExiting` flag so only one notification is ever on screen at a time, and the next one is shown only after the previous one's exit animation fully completes.
- **Fixed:** Dedupe key leak — the `_keys` Set was never cleaned up on dismiss, so a notification with a given `key` could only ever be shown once per session. Replaced with a `_keyToId` Map that is cleared precisely in `unregisterActive()`.
- **Fixed:** `unregisterActive()` read from `_active` after already removing the entry, so the dedupe key associated with a dismissed notification was never released.
- **Fixed:** Progress bar was driven by the entrance `AnimationController` (0 → 1 over 350 ms) instead of a real countdown. Introduced a dedicated `_progressCtrl` that runs independently over the full notification `duration`, giving a correct depleting bar.
- **Fixed:** `AwesomeDismissDirection.any` was mapped to `DismissDirection.none` (a leftover incorrect comment-only fix from 1.0.3). Now correctly maps to `DismissDirection.startToEnd`.
- **Fixed:** `dismissAll()` iterated directly over `_active.values` while removing entries, causing a concurrent-modification error. Now iterates over a copied list.
- **Fixed:** Layout jank caused by `Dismissible` inside an unbounded `Stack`. Added `StackFit.expand` so the Stack always has a definite size.
- **Added:** `AwesomeSnackbar.markExiting(id)` — called at the start of the exit animation to block queue promotion during the reverse animation, closing the async gap between `_dismiss()` being called and `unregisterActive()` completing.
- **Improved:** `GestureDetector` on the dismiss × button and action buttons now uses `HitTestBehavior.opaque` for more reliable tap detection on small targets.

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