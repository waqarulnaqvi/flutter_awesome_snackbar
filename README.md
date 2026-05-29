# 🔥 flutter_awesome_snackbar

The most powerful, beautiful, and developer-friendly Flutter notification package.

**Pure Flutter — zero external dependencies.** Everything you need from a modern notification system, plus haptics, scheduling, routing, history, grouping, path animations, and more — all built on Flutter's own APIs.

---

## ✨ Why flutter_awesome_snackbar?

| Feature | flutter_awesome_snackbar | fluttertoast | another_flushbar | bot_toast | GetX Snackbar |
| --- | --- | --- | --- | --- | --- |
| All platforms | ✅ | ⚠️ Limited | ✅ | ✅ | ✅ |
| State mgmt. agnostic | ✅ | ✅ | ✅ | ✅ | ❌ |
| Queue system | ✅ | ❌ | ✅ | ✅ | ✅ |
| Priority queue | ✅ | ❌ | ❌ | ❌ | ❌ |
| Future tracking API | ✅ | ❌ | ❌ | ❌ | ❌ |
| Glassmorphism | ✅ | ❌ | ❌ | ❌ | ❌ |
| Built-in animations | ✅ 9 styles | ❌ | ⚠️ 2 styles | ⚠️ 3 styles | ⚠️ Basic |
| Custom widget | ✅ | ❌ | ✅ | ✅ | ✅ |
| Gradient backgrounds | ✅ | ❌ | ❌ | ❌ | ✅ |
| Duplicate prevention | ✅ | ❌ | ❌ | ✅ | ❌ |
| Dismiss by ID | ✅ | ❌ | ❌ | ✅ | ❌ |
| Progress bar | ✅ | ❌ | ✅ | ❌ | ✅ |
| RTL support | ✅ | ✅ | ✅ | ✅ | ✅ |
| Dart 3 / null-safe | ✅ | ✅ | ✅ | ✅ | ✅ |
| **★ Zero dependencies** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Haptic feedback** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Scheduling / delay** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Tap-to-route** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Notification history** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Grouped notifications** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Custom path animation** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Flip animation** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Dismiss group** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Accessibility labels** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Timestamp display** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Tap-through support** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Overlay scrim** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Cancel scheduled** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **★ Dismiss callback** | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 🚀 Quick Start (2 minutes)

### 1. Install

```yaml
dependencies:
  flutter_awesome_snackbar: ^1.0.0

```

```sh
flutter pub get

```

### 2. Initialize

Wrap your `MaterialApp.builder` — that's it:

```dart
import 'package:flutter_awesome_snackbar/flutter_awesome_snackbar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: AwesomeWidget.init(), // ← one line
      home: HomeScreen(),
    );
  }
}

```

### 3. Show notifications

```dart
AwesomeSnackbar.success("Profile saved!");
AwesomeSnackbar.error("Payment failed.");
AwesomeSnackbar.warning("Weak internet connection.");
AwesomeSnackbar.info("Version 2.0 is available.");

```

Done. 🎉

---

## 📦 Zero External Dependencies

`flutter_awesome_snackbar` is built entirely on Flutter's own APIs:

* **Haptic feedback** — Flutter's built-in `HapticFeedback` (`services` package)
* **Glassmorphism** — `dart:ui`'s `ImageFilter.blur` + `BackdropFilter`
* **Animations** — Flutter's `AnimationController`, `SlideTransition`, `FadeTransition`, etc.
* **Overlay system** — Flutter's native `Overlay` + `OverlayEntry`

No `vibration`, `audioplayers`, `flutter_animate`, or any other third-party package is required.

---

## 🎛️ All APIs at a Glance

### Convenience methods

```dart
AwesomeSnackbar.success("Saved");
AwesomeSnackbar.error("Failed", title: "Oops");
AwesomeSnackbar.warning("Low battery");
AwesomeSnackbar.info("New update");

final id = AwesomeSnackbar.loading("Uploading...");
AwesomeSnackbar.dismissById(id);
AwesomeSnackbar.dismissAll();

```

### Full control with AwesomeOptions

```dart
AwesomeSnackbar.show(AwesomeOptions(
  title: "No Internet",
  message: "Please check your connection.",
  type: AwesomeType.error,
  position: AwesomePosition.top,
  animation: AwesomeAnimation.elastic,
  duration: Duration(seconds: 5),
  actionText: "Retry",
  onAction: () => reconnect(),
  secondaryActionText: "Dismiss",
  onSecondaryAction: AwesomeSnackbar.dismissAll,
  showProgress: true,
  dismissDirection: AwesomeDismissDirection.horizontal,
  priority: AwesomePriority.critical,
  onDismiss: () => print("dismissed"),
  dismissOnTap: false,
));

```

### Future tracking

```dart
await AwesomeSnackbar.future(
  future: uploadData(),
  loading: "Uploading your file...",
  success: "Upload complete! 🎉",
  error: "Upload failed. Please retry.",
);

```

Dynamic messages based on result:

```dart
await AwesomeSnackbar.future<User>(
  future: fetchUser(),
  loading: "Fetching profile...",
  success: (user) => "Welcome back, ${user.name}!",
  error: (e) => "Error: ${e.toString()}",
);

```

### Extension methods

```dart
// On BuildContext
context.flashSuccess("Saved!");
context.flashError("Failed!");

// On String
"Done!".flashSuccess();
"Oops!".flashError();

// On Future
uploadFile().flashFuture(
  loading: "Uploading...",
  success: (_) => "Done!",
  error: (e) => "Failed: $e",
);

```

---

## ★ Unique Features

### Haptic feedback (built-in, no extra package)

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.success,
  message: "Saved!",
  haptic: AwesomeHaptic.success,  // uses Flutter's HapticFeedback
));

```

Available: `none`, `light`, `medium`, `heavy`, `success`, `warning`, `error`, `vibrate`

Set globally:

```dart
AwesomeSnackbar.configure(AwesomeConfig(
  defaultHaptic: AwesomeHaptic.light,
));

```

### Scheduling & delayed notifications

```dart
final sid = AwesomeSnackbar.schedule(
  delay: Duration(seconds: 30),
  options: AwesomeOptions(
    type: AwesomeType.info,
    message: "Reminder: stand up and stretch!",
  ),
);

// Cancel if no longer needed
AwesomeSnackbar.cancelScheduled(sid);

```

### Tap-to-route

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.info,
  message: "Your order shipped. Tap to track →",
  routeName: "/order-tracking",
  dismissOnTap: true,
));

```

### Notification history

```dart
// Read all history (newest first)
final records = AwesomeHistory.instance.all;

// Filter
final errors = AwesomeHistory.instance.byType(AwesomeType.error);
final tagged = AwesomeHistory.instance.byTag("checkout");

// Unread count
final unread = AwesomeHistory.instance.unreadCount;

// Mark all read / clear
AwesomeHistory.instance.markAllRead();
AwesomeHistory.instance.clear();

```

### Grouped notifications

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.info,
  message: "Alice sent you a message",
  groupKey: "chat_alice",
));

// Dismiss the entire group
AwesomeSnackbar.dismissGroup("chat_alice");

```

### Custom path animation

```dart
AwesomeSnackbar.show(AwesomeOptions(
  message: "Follows a custom arc!",
  animation: AwesomeAnimation.path,
  pathAnimation: Path()
    ..moveTo(-200, 0)
    ..quadraticBezierTo(0, -150, 0, 0),
));

```

### Flip animation (3D card flip)

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.info,
  message: "Card flip entrance",
  animation: AwesomeAnimation.flip,
));

```

---

## 🎨 Customization

### Global config

```dart
AwesomeSnackbar.configure(AwesomeConfig(
  position: AwesomePosition.bottom,
  animation: AwesomeAnimation.bounce,
  duration: Duration(seconds: 3),
  borderRadius: BorderRadius.circular(20),
  blur: true,                          // glassmorphism globally
  maxVisible: 3,
  stackedMode: false,
  showProgress: true,
  defaultHaptic: AwesomeHaptic.light,
  enableHistory: true,
  showTimestamp: true,
  overlayOpacity: 0.2,
  tapThroughEnabled: false,
  safeAreaInsets: true,
));

```

### Custom theme per notification

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.custom,
  message: "Premium feature unlocked.",
  themeData: AwesomeThemeData(
    backgroundColor: Color(0xFF1E1B4B),
    textColor: Colors.white,
    titleColor: Colors.amber,
    iconColor: Colors.amberAccent,
    actionColor: Colors.amber,
    progressColor: Colors.amber,
    borderColor: Color(0xFF312E81),
    borderWidth: 1,
    elevation: 8,
  ),
));

```

### Gradient background

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.custom,
  title: "Pro Plan",
  message: "Upgrade to unlock all features.",
  themeData: AwesomeThemeData(
    backgroundColor: Colors.transparent,
    textColor: Colors.white,
    iconColor: Colors.white,
    actionColor: Colors.amber,
    gradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    ),
  ),
  actionText: "Upgrade",
  onAction: () => openUpgradeScreen(),
));

```

### Glassmorphism (dart:ui — no external package)

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.success,
  message: "Saved with glass effect!",
  themeData: AwesomeThemeData.glassSuccess(dark: false),
));

```

Or globally:

```dart
AwesomeSnackbar.configure(AwesomeConfig(blur: true));

```

### Custom widget

```dart
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.custom,
  customWidget: Row(
    children: [
      CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alice sent you a message"),
            Text("Hey! Are you free tonight?",
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ],
  ),
));

```

### Custom animation builder

```dart
AwesomeSnackbar.show(AwesomeOptions(
  message: "Custom animation!",
  animationBuilder: (controller, child) {
    return SlideTransition(
      position: Tween(begin: Offset(-2, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      ),
      child: child,
    );
  },
));

```

---

## 🎞️ Animations (9 built-in)

| Name | Description |
| --- | --- |
| `AwesomeAnimation.slide` | Slides in from the nearest edge |
| `AwesomeAnimation.fade` | Fades in/out smoothly |
| `AwesomeAnimation.scale` | Scales from center with ease-out-back |
| `AwesomeAnimation.elastic` | Spring-like elastic entrance |
| `AwesomeAnimation.bounce` | Bouncy entrance |
| `AwesomeAnimation.rotation` | Rotation + scale + fade |
| `AwesomeAnimation.ios` | iOS-style cubic-emphasized curve |
| `AwesomeAnimation.flip` | 3D card-flip entrance ★ |
| `AwesomeAnimation.path` | Follows a custom `Path` ★ |

---

## 📋 Queue & Priority

```dart
// Standard FIFO order
AwesomeSnackbar.show(AwesomeOptions(
  message: "Normal",
  priority: AwesomePriority.normal,
));

// Jumps ahead of normal items
AwesomeSnackbar.show(AwesomeOptions(
  message: "Important!",
  priority: AwesomePriority.high,
));

// Goes to the front immediately
AwesomeSnackbar.show(AwesomeOptions(
  type: AwesomeType.error,
  message: "Critical error!",
  priority: AwesomePriority.critical,
));

```

---

## 🔑 Duplicate Prevention

```dart
// Only one notification is ever shown, even if called multiple times
for (int i = 0; i < 5; i++) {
  AwesomeSnackbar.show(AwesomeOptions(
    message: "You are offline",
    key: "offline_banner",
  ));
}

```

---

## 🌐 Platform Support

| Platform | Supported |
| --- | --- |
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |

---

## 🧩 State Management

Zero dependency on any state management solution:

* ✅ GetX — call `AwesomeSnackbar.success(...)` anywhere
* ✅ Provider — no setup needed
* ✅ Riverpod — works in any `ref.read()` or callback
* ✅ Bloc / Cubit — call from `BlocListener`
* ✅ MobX — call from reactions
* ✅ Stacked — call from `ViewModelBuilder`
* ✅ setState — just call it!

---

## 🗺️ Roadmap

* ❌ Rich push-style notifications (image, large icon)
* ❌ Persistent notification badge widget
* ❌ Swipe-right to mark as actioned
* ❌ Cross-session history persistence (SharedPreferences)
* ❌ Notification grouping collapse UI

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repo
2. Create your feature branch: `git checkout -b feat/amazing-feature`
3. Commit: `git commit -m 'feat: add amazing feature'`
4. Push: `git push origin feat/amazing-feature`
5. Open a pull request

---

## 📄 License

MIT License © 2025 Mysterious Coder