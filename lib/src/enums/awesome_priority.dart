/// Queue priority.
enum AwesomePriority {
  /// Standard FIFO order.
  normal,

  /// Jumps ahead of [normal] items.
  high,

  /// Goes to the front immediately.
  critical,
}
