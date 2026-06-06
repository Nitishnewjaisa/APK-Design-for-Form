/// Reusable retry logic for field detection and fill operations.
class RetryEngine {
  final int maxAttempts;
  final Duration delay;

  const RetryEngine({
    this.maxAttempts = 3,
    this.delay = const Duration(milliseconds: 400),
  });

  Future<T?> run<T>({
    required Future<T?> Function() action,
    required bool Function(T result) isSuccess,
    void Function(int attempt, Object? error)? onRetry,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await action();
        if (result != null && isSuccess(result)) return result;
        onRetry?.call(attempt, null);
      } catch (e) {
        onRetry?.call(attempt, e);
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(delay);
      }
    }
    return null;
  }

  Future<bool> runBool({
    required Future<bool> Function() action,
    void Function(int attempt)? onRetry,
  }) async {
    final result = await run<bool>(
      action: action,
      isSuccess: (r) => r,
      onRetry: (a, _) => onRetry?.call(a),
    );
    return result ?? false;
  }
}
