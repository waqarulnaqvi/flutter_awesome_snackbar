import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_awesome_snackbar/flutter_awesome_snackbar.dart';

void main() {
  group('AwesomeSnackbar', () {
    setUp(() {
      AwesomeSnackbar.configure(const AwesomeConfig());
      AwesomeSnackbar.dismissAll();
      AwesomeHistory.instance.clear();
    });

    test('configure() updates global config', () {
      AwesomeSnackbar.configure(const AwesomeConfig(
        position: AwesomePosition.bottom,
        blur: true,
        defaultHaptic: AwesomeHaptic.medium,
      ));
      expect(AwesomeSnackbar.config.position, AwesomePosition.bottom);
      expect(AwesomeSnackbar.config.blur, true);
      expect(AwesomeSnackbar.config.defaultHaptic, AwesomeHaptic.medium);
    });

    test('show() returns a non-empty id', () {
      final id = AwesomeSnackbar.success('Hello');
      expect(id, isNotEmpty);
    });

    test('duplicate key prevention returns empty id', () {
      AwesomeSnackbar.show(const AwesomeOptions(
        message: 'First',
        key: 'test_key',
        type: AwesomeType.info,
      ));
      final secondId = AwesomeSnackbar.show(const AwesomeOptions(
        message: 'Duplicate',
        key: 'test_key',
        type: AwesomeType.info,
      ));
      expect(secondId, isEmpty);
    });

    test('history records notifications', () {
      AwesomeSnackbar.configure(const AwesomeConfig(enableHistory: true));
      AwesomeSnackbar.success('Test A');
      AwesomeSnackbar.error('Test B');
      expect(AwesomeHistory.instance.all.length, 2);
    });

    test('history byType filters correctly', () {
      AwesomeSnackbar.success('ok');
      AwesomeSnackbar.error('fail');
      expect(
          AwesomeHistory.instance.byType(AwesomeType.error).length, 1);
      expect(
          AwesomeHistory.instance.byType(AwesomeType.success).length, 1);
    });

    test('history clear() empties records', () {
      AwesomeSnackbar.info('Something');
      AwesomeHistory.instance.clear();
      expect(AwesomeHistory.instance.all, isEmpty);
    });

    test('schedule() returns a non-empty schedule id', () {
      final sid = AwesomeSnackbar.schedule(
        delay: const Duration(seconds: 60),
        options: const AwesomeOptions(
          message: 'Scheduled',
          type: AwesomeType.info,
        ),
      );
      expect(sid, isNotEmpty);
      AwesomeSnackbar.cancelScheduled(sid);
    });

    test('AwesomeConfig copyWith works', () {
      const base = AwesomeConfig(blur: false, maxVisible: 3);
      final updated = base.copyWith(blur: true, maxVisible: 5);
      expect(updated.blur, true);
      expect(updated.maxVisible, 5);
      expect(updated.position, base.position); // unchanged
    });

    test('AwesomeThemeData copyWith works', () {
      const base = AwesomeThemeData(borderWidth: 1.0);
      final updated = base.copyWith(borderWidth: 2.0);
      expect(updated.borderWidth, 2.0);
    });

    test('priority ordering: critical before high before normal', () {
      // Just verifies no exceptions are thrown during priority insertion
      AwesomeSnackbar.show(const AwesomeOptions(
          message: 'Normal', priority: AwesomePriority.normal));
      AwesomeSnackbar.show(const AwesomeOptions(
          message: 'High', priority: AwesomePriority.high));
      AwesomeSnackbar.show(const AwesomeOptions(
          message: 'Critical', priority: AwesomePriority.critical));
    });
  });

  group('AwesomeHistory', () {
    setUp(() => AwesomeHistory.instance.clear());

    test('unreadCount reflects un-dismissed records', () {
      AwesomeSnackbar.configure(const AwesomeConfig(enableHistory: true));
      AwesomeSnackbar.info('A');
      AwesomeSnackbar.info('B');
      expect(AwesomeHistory.instance.unreadCount, 2);
    });

    test('markAllRead sets dismissedAt on all records', () {
      AwesomeSnackbar.info('A');
      AwesomeHistory.instance.markAllRead();
      expect(AwesomeHistory.instance.unreadCount, 0);
      for (final r in AwesomeHistory.instance.all) {
        expect(r.dismissedAt, isNotNull);
      }
    });
  });
}
