import 'dart:collection';
import 'dart:typed_data';

/// Entry containing cached image bytes and optional expiration timestamp.
class CacheEntry {
  /// The binary image payload.
  final Uint8List bytes;

  /// The timestamp when this entry was created.
  final DateTime createdAt;

  /// Optional expiration timestamp.
  final DateTime? expiresAt;

  /// Creates a [CacheEntry].
  CacheEntry({
    required this.bytes,
    required this.createdAt,
    this.expiresAt,
  });

  /// Whether this entry has exceeded its time-to-live.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Abstract contract for offline image storage backends.
abstract class ImageCacheStore {
  /// Retrieves cached image bytes for the given [key]. Returns null on miss or expiry.
  Future<Uint8List?> get(String key);

  /// Stores binary image bytes associated with [key] and optional [ttl].
  Future<void> put(String key, Uint8List bytes, {Duration? ttl});

  /// Checks if an unexpired entry exists for [key].
  Future<bool> has(String key);

  /// Evicts a specific entry from the cache.
  Future<void> evict(String key);

  /// Purges all entries from the store.
  Future<void> clear();
}

/// A robust in-memory LRU cache store with TTL expiration and max entries limit.
class MemoryImageCacheStore implements ImageCacheStore {
  final int maxEntries;
  final LinkedHashMap<String, CacheEntry> _entries = LinkedHashMap();

  /// Creates a [MemoryImageCacheStore] with a default limit of 150 items.
  MemoryImageCacheStore({this.maxEntries = 150});

  @override
  Future<Uint8List?> get(String key) async {
    final entry = _entries.remove(key);
    if (entry == null) return null;

    if (entry.isExpired) {
      return null;
    }

    // Re-insert to mark as most recently accessed
    _entries[key] = entry;
    return entry.bytes;
  }

  @override
  Future<void> put(String key, Uint8List bytes, {Duration? ttl}) async {
    _entries.remove(key);

    if (_entries.length >= maxEntries) {
      // Evict oldest (least recently used) entry
      final oldestKey = _entries.keys.first;
      _entries.remove(oldestKey);
    }

    _entries[key] = CacheEntry(
      bytes: bytes,
      createdAt: DateTime.now(),
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  @override
  Future<bool> has(String key) async {
    final entry = _entries[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _entries.remove(key);
      return false;
    }
    return true;
  }

  @override
  Future<void> evict(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  /// Current number of stored entries.
  int get count => _entries.length;
}

/// Global coordinator for offline image caching across the app.
class OfflineImageCacheManager {
  static OfflineImageCacheManager? _instance;

  /// The active cache store backing the manager.
  ImageCacheStore store;

  OfflineImageCacheManager._({ImageCacheStore? store})
      : store = store ?? MemoryImageCacheStore();

  /// Singleton access to the global cache manager.
  static OfflineImageCacheManager get instance {
    _instance ??= OfflineImageCacheManager._();
    return _instance!;
  }

  /// Sets a custom storage backend (e.g. disk/database cache).
  static void setCustomStore(ImageCacheStore store) {
    instance.store = store;
  }

  /// Retrieves an image from the active store.
  Future<Uint8List?> get(String key) => store.get(key);

  /// Saves an image to the active store.
  Future<void> put(String key, Uint8List bytes, {Duration? ttl}) =>
      store.put(key, bytes, ttl: ttl);

  /// Checks if an entry exists.
  Future<bool> has(String key) => store.has(key);

  /// Evicts a specific key.
  Future<void> evict(String key) => store.evict(key);

  /// Clears all entries.
  Future<void> clear() => store.clear();
}
