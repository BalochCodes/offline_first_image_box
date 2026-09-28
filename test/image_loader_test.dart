import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_image_box/offline_first_image_box.dart';

void main() {
  group('ImageLoader Multi-Tier Pipeline Tests', () {
    late MemoryImageCacheStore store;
    final testBytes = Uint8List.fromList([10, 20, 30, 40]);

    setUp(() {
      store = MemoryImageCacheStore();
      ImageLoader.setCustomNetworkFetcher(null);
    });

    tearDown(() {
      ImageLoader.setCustomNetworkFetcher(null);
    });

    test('cacheFirst returns cached bytes without hitting network', () async {
      await store.put('https://example.com/test.png', testBytes);

      bool networkCalled = false;
      ImageLoader.setCustomNetworkFetcher((uri) async {
        networkCalled = true;
        return testBytes;
      });

      final result = await ImageLoader.load(
        imageUrl: 'https://example.com/test.png',
        rule: CacheRule.cacheFirst,
        cacheStore: store,
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, ImageSource.cache);
      expect(result.bytes, equals(testBytes));
      expect(networkCalled, isFalse);
    });

    test('cacheFirst fetches from network on cache miss and populates cache', () async {
      bool networkCalled = false;
      ImageLoader.setCustomNetworkFetcher((uri) async {
        networkCalled = true;
        return testBytes;
      });

      final result = await ImageLoader.load(
        imageUrl: 'https://example.com/new.png',
        rule: CacheRule.cacheFirst,
        cacheStore: store,
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, ImageSource.network);
      expect(networkCalled, isTrue);

      // Verify cached in store
      expect(await store.has('https://example.com/new.png'), isTrue);
    });

    test('networkFirst falls back to cache if network request fails', () async {
      await store.put('https://example.com/cached.png', testBytes);

      // Network fails
      ImageLoader.setCustomNetworkFetcher((uri) async {
        throw Exception('Network offline');
      });

      final result = await ImageLoader.load(
        imageUrl: 'https://example.com/cached.png',
        rule: CacheRule.networkFirst,
        retryPolicy: const RetryPolicy(maxRetries: 0),
        cacheStore: store,
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, ImageSource.cache);
      expect(result.bytes, equals(testBytes));
    });
  });
}
