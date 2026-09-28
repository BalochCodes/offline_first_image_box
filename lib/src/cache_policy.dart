import 'dart:math' as math;

/// Strategy determining whether cached local images or remote network assets take priority.
enum CacheRule {
  /// Check local cache first; if present, display immediately without network overhead.
  /// If missing, retrieve from network and cache the response.
  cacheFirst,

  /// Attempt fresh fetch from network first; if offline or network fails, fall back to cache.
  networkFirst,

  /// Only load from local cache, never attempting a network request.
  cacheOnly,

  /// Always fetch from network, bypassing and ignoring local cache.
  networkOnly,
}

/// The resolved origin source of a rendered image.
enum ImageSource {
  /// Freshly fetched over the network.
  network,

  /// Loaded from persistent local disk/memory cache.
  cache,

  /// Loaded from bundled asset fallback.
  asset,

  /// Failed to load from any tier.
  none,
}

/// Configuration policy for auto-retrying failed network image downloads.
class RetryPolicy {
  /// Maximum number of retry attempts before giving up. Defaults to 3.
  final int maxRetries;

  /// Initial duration before the first retry attempt. Defaults to 1 second.
  final Duration initialDelay;

  /// Maximum ceiling delay between retry attempts. Defaults to 10 seconds.
  final Duration maxDelay;

  /// Whether each subsequent retry doubles the backoff delay. Defaults to true.
  final bool exponentialBackoff;

  /// Creates a [RetryPolicy].
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.exponentialBackoff = true,
  });

  /// Calculates the backoff delay duration for a specific 1-indexed [attemptNumber].
  Duration getDelay(int attemptNumber) {
    if (attemptNumber <= 1 || !exponentialBackoff) {
      return initialDelay;
    }

    final multiplier = math.pow(2, attemptNumber - 1).toInt();
    final calculatedMs = initialDelay.inMilliseconds * multiplier;
    final cappedMs = math.min(calculatedMs, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs);
  }
}
