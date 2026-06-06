/// Shared scroll behavior configuration for all platforms.
class ScrollConfig {
  final int maxRetries;
  final Duration delay;
  final double swipeRatio;

  const ScrollConfig({
    this.maxRetries = 8,
    this.delay = const Duration(milliseconds: 600),
    this.swipeRatio = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'maxRetries': maxRetries,
        'delayMs': delay.inMilliseconds,
        'swipeRatio': swipeRatio,
      };
}
