import 'package:flutter/material.dart';
import 'package:flutter_awesome_snackbar/flutter_awesome_snackbar.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_awesome_snackbar demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // ← One line — that's all the setup required.
      builder: AwesomeWidget.init(
        config: const AwesomeConfig(
          position: AwesomePosition.top,
          animation: AwesomeAnimation.elastic,
          blur: false,
          showProgress: true,
          defaultHaptic: AwesomeHaptic.light,
          enableHistory: true,
        ),
      ),
      home: const DemoScreen(),
    );
  }
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_awesome_snackbar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Convenience shortcuts ──────────────────────────────────────
          _Section(title: 'Convenience shortcuts', children: [
            _Btn('Success', Icons.check_circle_outline,
                () => AwesomeSnackbar.success('Profile saved!')),
            _Btn('Error', Icons.error_outline,
                () => AwesomeSnackbar.error('Payment failed.', title: 'Oops')),
            _Btn('Warning', Icons.warning_amber_outlined,
                () => AwesomeSnackbar.warning('Weak internet connection.')),
            _Btn('Info', Icons.info_outline,
                () => AwesomeSnackbar.info('Version 2.0 is available.')),
          ]),

          // ── Full options ───────────────────────────────────────────────
          _Section(title: 'Full options', children: [
            _Btn('With actions', Icons.touch_app_outlined, () {
              AwesomeSnackbar.show(AwesomeOptions(
                title: 'No Internet',
                message: 'Please check your connection.',
                type: AwesomeType.error,
                position: AwesomePosition.top,
                animation: AwesomeAnimation.elastic,
                duration: const Duration(seconds: 6),
                actionText: 'Retry',
                onAction: () => debugPrint('Retry tapped'),
                secondaryActionText: 'Dismiss',
                onSecondaryAction: AwesomeSnackbar.dismissAll,
                showProgress: true,
                priority: AwesomePriority.critical,
              ));
            }),
            _Btn('Gradient bg', Icons.gradient_outlined, () {
              AwesomeSnackbar.show(AwesomeOptions(
                type: AwesomeType.custom,
                title: 'Pro Plan',
                message: 'Upgrade to unlock all features.',
                themeData: AwesomeThemeData(
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                  iconColor: Colors.amber,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                ),
                actionText: 'Upgrade',
                onAction: () => debugPrint('Upgrade tapped'),
              ));
            }),
            _Btn('Glassmorphism', Icons.blur_on_outlined, () {
              AwesomeSnackbar.show(AwesomeOptions(
                type: AwesomeType.success,
                message: 'Saved with glass effect!',
                themeData: AwesomeThemeData.glassSuccess(),
              ));
            }),
          ]),

          // ── Animations ────────────────────────────────────────────────
          _Section(
            title: 'Animations (${AwesomeAnimation.values.length} built-in)',
            children: AwesomeAnimation.values
                .map((anim) => _Btn(
                      anim.name,
                      Icons.animation_outlined,
                      () => AwesomeSnackbar.show(AwesomeOptions(
                        type: AwesomeType.info,
                        message: '${anim.name} animation',
                        animation: anim,
                      )),
                    ))
                .toList(),
          ),

          // ── Future tracking ───────────────────────────────────────────
          _Section(title: 'Future tracking', children: [
            _Btn('Await future', Icons.hourglass_top_outlined, () {
              AwesomeSnackbar.future<String>(
                future: Future.delayed(
                    const Duration(seconds: 2), () => 'Alice'),
                loading: 'Uploading your file...',
                success: (name) => 'Welcome back, $name!',
                error: (e) => 'Error: $e',
              );
            }),
          ]),

          // ── NEW: Scheduling ───────────────────────────────────────────
          _Section(title: '★ NEW — Scheduling', children: [
            _Btn('Schedule (3 s)', Icons.schedule_outlined, () {
              AwesomeSnackbar.schedule(
                delay: const Duration(seconds: 3),
                options: const AwesomeOptions(
                  type: AwesomeType.info,
                  title: 'Scheduled!',
                  message: 'This appeared 3 seconds after you tapped.',
                ),
              );
            }),
          ]),

          // ── NEW: Haptics ──────────────────────────────────────────────
          _Section(title: '★ NEW — Haptic feedback', children: [
            ...AwesomeHaptic.values.where((h) => h != AwesomeHaptic.none).map(
                  (h) => _Btn(h.name, Icons.vibration_outlined, () {
                    AwesomeSnackbar.show(AwesomeOptions(
                      type: AwesomeType.success,
                      message: 'Haptic: ${h.name}',
                      haptic: h,
                    ));
                  }),
                ),
          ]),

          // ── NEW: Routing ──────────────────────────────────────────────
          _Section(title: '★ NEW — Tap-to-route', children: [
            _Btn('Tap → /settings', Icons.route_outlined, () {
              AwesomeSnackbar.show(const AwesomeOptions(
                type: AwesomeType.info,
                message: 'Tap to go to settings →',
                routeName: '/settings',
                dismissOnTap: true,
              ));
            }),
          ]),

          // ── NEW: Grouped notifications ────────────────────────────────
          _Section(title: '★ NEW — Grouped notifications', children: [
            _Btn('Show group (×3)', Icons.group_work_outlined, () {
              for (var i = 1; i <= 3; i++) {
                AwesomeSnackbar.show(AwesomeOptions(
                  type: AwesomeType.info,
                  message: 'Group message #$i',
                  groupKey: 'demo_group',
                ));
              }
            }),
            _Btn('Dismiss group', Icons.layers_clear_outlined,
                () => AwesomeSnackbar.dismissGroup('demo_group')),
          ]),

          // ── NEW: History panel ────────────────────────────────────────
          _Section(title: '★ NEW — History', children: [
            _Btn('Show history', Icons.history_outlined, () {
              final records = AwesomeHistory.instance.all;
              AwesomeSnackbar.info(
                '${records.length} notifications in history.',
                title: 'History',
              );
            }),
            _Btn('Clear history', Icons.delete_outline,
                () => AwesomeHistory.instance.clear()),
          ]),

          // ── Extension methods ─────────────────────────────────────────
          _Section(title: 'Extension methods', children: [
            _Btn('String.flashSuccess()', Icons.code,
                () => 'Done!'.flashSuccess()),
            _Btn('context.flashError()', Icons.code,
                () => context.flashError('Something went wrong')),
            _Btn('Future.flashFuture()', Icons.code, () {
              Future.delayed(const Duration(seconds: 1))
                  .flashFuture(
                loading: 'Working...',
                success: (_) => 'Completed!',
                error: (e) => 'Failed: $e',
              );
            }),
          ]),

          // ── Queue & dismiss ───────────────────────────────────────────
          _Section(title: 'Queue & dismiss', children: [
            _Btn('Loading (persistent)', Icons.loop_outlined,
                () => AwesomeSnackbar.loading('Uploading…')),
            _Btn('Dismiss all', Icons.cancel_outlined,
                AwesomeSnackbar.dismissAll),
            _Btn('Duplicate prevention (key)', Icons.filter_none_outlined,
                () {
              for (var i = 0; i < 5; i++) {
                AwesomeSnackbar.show(const AwesomeOptions(
                  message: 'Only shown once (dedup key)',
                  key: 'dedup_demo',
                  type: AwesomeType.warning,
                ));
              }
            }),
          ]),

          // ── Custom widget ─────────────────────────────────────────────
          _Section(title: 'Custom widget', children: [
            _Btn('Chat message style', Icons.chat_bubble_outline, () {
              AwesomeSnackbar.show(AwesomeOptions(
                type: AwesomeType.custom,
                customWidget: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.indigo.shade100,
                      child: const Text('A',
                          style: TextStyle(color: Colors.indigo)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alice',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text('Hey! Are you free tonight?',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
            }),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
    );
  }
}
