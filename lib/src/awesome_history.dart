import 'awesome_options.dart';
import 'enums/awesome_type.dart';

/// A record of one previously shown notification.
class AwesomeRecord {
  const AwesomeRecord({
    required this.id,
    required this.options,
    required this.shownAt,
    this.dismissedAt,
    this.wasActioned = false,
  });

  final String id;
  final AwesomeOptions options;
  final DateTime shownAt;
  final DateTime? dismissedAt;

  /// Whether the user tapped the primary action button.
  final bool wasActioned;

  AwesomeRecord copyWith({DateTime? dismissedAt, bool? wasActioned}) {
    return AwesomeRecord(
      id: id,
      options: options,
      shownAt: shownAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      wasActioned: wasActioned ?? this.wasActioned,
    );
  }
}

/// Stores a capped history of all notifications shown during the session.
///
/// ```dart
/// final records = AwesomeHistory.instance.all;
/// AwesomeHistory.instance.clear();
/// ```
class AwesomeHistory {
  AwesomeHistory._();

  static final AwesomeHistory instance = AwesomeHistory._();

  final List<AwesomeRecord> _records = [];

  /// All records, newest first.
  List<AwesomeRecord> get all => List.unmodifiable(_records);

  /// Filter by [AwesomeType].
  List<AwesomeRecord> byType(AwesomeType type) =>
      _records.where((r) => r.options.type == type).toList();

  /// Filter by arbitrary [tag].
  List<AwesomeRecord> byTag(String tag) =>
      _records.where((r) => r.options.tag == tag).toList();

  /// Unread count (records not yet dismissed).
  int get unreadCount => _records.where((r) => r.dismissedAt == null).length;

  /// Mark all records as read (sets dismissedAt to now).
  void markAllRead() {
    final now = DateTime.now();
    for (var i = 0; i < _records.length; i++) {
      if (_records[i].dismissedAt == null) {
        _records[i] = _records[i].copyWith(dismissedAt: now);
      }
    }
  }

  /// Clear entire history.
  void clear() => _records.clear();

  // ─── Internal API ────────────────────────────────────────────────────────
  // These are called by the controller. The underscores have been removed
  // so they can be accessed from outside this file.

  void add(AwesomeRecord record) => _records.insert(0, record);

  void markDismissed(String id) {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _records[idx] = _records[idx].copyWith(dismissedAt: DateTime.now());
    }
  }

  void markActioned(String id) {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _records[idx] = _records[idx].copyWith(wasActioned: true);
    }
  }
}