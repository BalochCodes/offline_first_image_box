import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'cache_policy.dart';
import 'image_cache_store.dart';

/// The result of an image fetch operation across cache, network, and fallback tiers.
class ImageFetchResult {
  /// Binary image bytes if resolved successfully.
  final Uint8List? bytes;

  /// The tier from which the image was resolved.
  final ImageSource source;

  /// Error details if the operation failed completely.
  final Object? error;

  /// Creates an [ImageFetchResult].
  const ImageFetchResult({
    this.bytes,
    required this.source,
    this.error,
  });

  /// Whether image data was successfully resolved.
  bool get isSuccess => bytes != null && bytes!.isNotEmpty;
}

/// Function signature for downloading raw bytes from a URI.
typedef NetworkBytesFetcher = Future<Uint8List> Function(Uri uri);

/// Internal image loading and fallback pipeline engine.
class ImageLoader {
  static NetworkBytesFetcher? _customFetcher;

  /// Overrides the default network downloader (useful for testing or offline simulations).
  static void setCustomNetworkFetcher(NetworkBytesFetcher? fetcher) {
    _customFetcher = fetcher;
  }

  /// Default network fetcher using Dart's [HttpClient].
  static Future<Uint8List> defaultNetworkFetcher(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode} while loading $uri');
      }

      final bytesBuilder = BytesBuilder();
      await for (final chunk in response) {
        bytesBuilder.add(chunk);
      }
      return bytesBuilder.takeBytes();
    } finally {
      client.close();
    }
  }

  /// Executes the multi-tier image retrieval pipeline based on [rule] and [retryPolicy].
  static Future<ImageFetchResult> load({
    required String imageUrl,
    String? cacheKey,
    CacheRule rule = CacheRule.cacheFirst,
    RetryPolicy retryPolicy = const RetryPolicy(),
    String? fallbackAsset,
    Duration? ttl,
    ImageCacheStore? cacheStore,
  }) async {
    final key = cacheKey ?? imageUrl;
    final store = cacheStore ?? OfflineImageCacheManager.instance.store;

    switch (rule) {
      case CacheRule.cacheFirst:
        // Tier 1: Check Local Cache
        final cached = await store.get(key);
        if (cached != null) {
          return ImageFetchResult(bytes: cached, source: ImageSource.cache);
        }

        // Tier 2: Network Fetch with Retry
        final netResult = await _fetchFromNetworkWithRetry(
          imageUrl: imageUrl,
          retryPolicy: retryPolicy,
        );
        if (netResult.isSuccess) {
          await store.put(key, netResult.bytes!, ttl: ttl);
          return netResult;
        }

        // Tier 3: Bundled Asset Fallback
        if (fallbackAsset != null) {
          final assetResult = await _loadAssetBytes(fallbackAsset);
          if (assetResult.isSuccess) return assetResult;
        }

        return ImageFetchResult(
          source: ImageSource.none,
          error: netResult.error,
        );

      case CacheRule.networkFirst:
        // Tier 1: Network Fetch with Retry
        final netResult = await _fetchFromNetworkWithRetry(
          imageUrl: imageUrl,
          retryPolicy: retryPolicy,
        );
        if (netResult.isSuccess) {
          await store.put(key, netResult.bytes!, ttl: ttl);
          return netResult;
        }

        // Tier 2: Fall back to Local Cache
        final cached = await store.get(key);
        if (cached != null) {
          return ImageFetchResult(bytes: cached, source: ImageSource.cache);
        }

        // Tier 3: Bundled Asset Fallback
        if (fallbackAsset != null) {
          final assetResult = await _loadAssetBytes(fallbackAsset);
          if (assetResult.isSuccess) return assetResult;
        }

        return ImageFetchResult(
          source: ImageSource.none,
          error: netResult.error,
        );

      case CacheRule.cacheOnly:
        final cached = await store.get(key);
        if (cached != null) {
          return ImageFetchResult(bytes: cached, source: ImageSource.cache);
        }
        if (fallbackAsset != null) {
          final assetResult = await _loadAssetBytes(fallbackAsset);
          if (assetResult.isSuccess) return assetResult;
        }
        return const ImageFetchResult(
          source: ImageSource.none,
          error: 'Image not found in local cache',
        );

      case CacheRule.networkOnly:
        final netResult = await _fetchFromNetworkWithRetry(
          imageUrl: imageUrl,
          retryPolicy: retryPolicy,
        );
        if (netResult.isSuccess) return netResult;

        if (fallbackAsset != null) {
          final assetResult = await _loadAssetBytes(fallbackAsset);
          if (assetResult.isSuccess) return assetResult;
        }
        return netResult;
    }
  }

  static Future<ImageFetchResult> _fetchFromNetworkWithRetry({
    required String imageUrl,
    required RetryPolicy retryPolicy,
  }) async {
    final fetcher = _customFetcher ?? defaultNetworkFetcher;
    final uri = Uri.parse(imageUrl);
    Object? lastError;

    int attempts = 0;
    while (attempts <= retryPolicy.maxRetries) {
      attempts++;
      try {
        final bytes = await fetcher(uri);
        return ImageFetchResult(bytes: bytes, source: ImageSource.network);
      } catch (e) {
        lastError = e;
        if (attempts <= retryPolicy.maxRetries) {
          final delay = retryPolicy.getDelay(attempts);
          await Future.delayed(delay);
        }
      }
    }

    return ImageFetchResult(
      source: ImageSource.none,
      error: lastError,
    );
  }

  static Future<ImageFetchResult> _loadAssetBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      return ImageFetchResult(bytes: bytes, source: ImageSource.asset);
    } catch (e) {
      return ImageFetchResult(source: ImageSource.none, error: e);
    }
  }
}
