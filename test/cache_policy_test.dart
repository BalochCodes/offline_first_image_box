import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_image_box/offline_first_image_box.dart';

void main() {
  group('RetryPolicy Tests', () {
    test('calculates exponential backoff delay correctly', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 8),
        exponentialBackoff: true,
      );

      expect(policy.getDelay(1), const Duration(seconds: 1));
      expect(policy.getDelay(2), const Duration(seconds: 2));
      expect(policy.getDelay(3), const Duration(seconds: 4));
      expect(policy.getDelay(4), const Duration(seconds: 8)); // Capped at maxDelay
      expect(policy.getDelay(5), const Duration(seconds: 8));
    });

    test('linear delay when exponentialBackoff is false', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 2),
        exponentialBackoff: false,
      );

      expect(policy.getDelay(1), const Duration(seconds: 2));
      expect(policy.getDelay(3), const Duration(seconds: 2));
    });
  });

  group('MemoryImageCacheStore Tests', () {
    test('stores and retrieves bytes', () async {
      final store = MemoryImageCacheStore(maxEntries: 3);
      final bytes = Uint8List.fromList([1, 2, 3]);

      await store.put('img1', bytes);
      expect(await store.has('img1'), isTrue);

      final retrieved = await store.get('img1');
      expect(retrieved, equals(bytes));
    });

    test('evicts least recently used entry when exceeding maxEntries', () async {
      final store = MemoryImageCacheStore(maxEntries: 2);
      final b1 = Uint8List.fromList([1]);
      final b2 = Uint8List.fromList([2]);
      final b3 = Uint8List.fromList([3]);

      await store.put('k1', b1);
      await store.put('k2', b2);

      // Access k1 to make it most recent
      await store.get('k1');

      // Put k3 -> should evict k2 (oldest)
      await store.put('k3', b3);

      expect(await store.has('k1'), isTrue);
      expect(await store.has('k2'), isFalse);
      expect(await store.has('k3'), isTrue);
    });

    test('respects TTL expiration', () async {
      final store = MemoryImageCacheStore();
      final bytes = Uint8List.fromList([10, 20]);

      // Negative TTL -> immediately expired
      await store.put('exp', bytes, ttl: const Duration(milliseconds: -10));

      expect(await store.has('exp'), isFalse);
      expect(await store.get('exp'), isNull);
    });
  });
}
