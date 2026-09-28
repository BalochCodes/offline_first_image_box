# offline_first_image_box

[![pub package](https://img.shields.io/pub/v/offline_first_image_box.svg?logo=dart&logoColor=white&style=flat-square)](https://pub.dev/packages/offline_first_image_box)
[![Pub Points](https://img.shields.io/badge/pub%20points-160%2F160-blue?style=flat-square)](https://pub.dev/packages/offline_first_image_box/score)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Likes](https://img.shields.io/pub/likes/offline_first_image_box?logo=dart&logoColor=white&style=flat-square)](https://pub.dev/packages/offline_first_image_box)

A bulletproof, resilient offline-first image loader for Flutter with progressive cross-fade, persistent local caching, auto-retry backoff, and multi-tier fallbacks.

---

## 🌟 Overview & Hook

Standard Flutter `Image.network` widgets collapse into ugly red error icons or blank squares whenever internet connectivity drops or fluctuates.

**offline_first_image_box** solves this with an intelligent multi-tier retrieval pipeline:
1. **Tier 1 (Instant Local Cache):** Instantly displays cached disk/memory copies across app sessions without network overhead.
2. **Tier 2 (Resilient Network Fetch with Retry):** Downloads fresh assets with automatic exponential backoff on timeouts or socket failures.
3. **Tier 3 (Bundled Asset Fallback):** Gracefully falls back to bundled asset illustrations if both network and cache fail.
4. **Tier 4 (Interactive Error Recovery):** Tap-to-retry error views keep user experience graceful and uninterrupted.

---

## ✨ Features

- 🛡️ **Offline-First Resilience:** Once cached, images load instantly without internet connection.
- 🌫️ **Two-Tier Progressive Cross-Fade:** Smooth fade transition between placeholder and full-resolution image.
- 🔄 **Smart Exponential Auto-Retry:** Handles transient network drops with configurable retry counts and backoff delays.
- 🗄️ **Memory & TTL Cache Management:** Automatic LRU eviction and expiration policies to prevent memory leaks.
- 📦 **Multi-Tier Fallbacks:** `Network ➔ Local Cache ➔ Bundled Asset ➔ Error / Tap-to-Retry`.
- 🎯 **Configurable Cache Rules:** Switch between `CacheRule.cacheFirst`, `networkFirst`, `cacheOnly`, or `networkOnly`.
- ⚡ **Zero Heavy Dependencies:** Lightweight and cross-platform across iOS, Android, macOS, Web, and Windows.

---

## 🚀 Installation

Add the dependency to your `pubspec.yaml`:

```bash
flutter pub add offline_first_image_box
```

Or manually:

```yaml
dependencies:
  offline_first_image_box: ^0.0.1
```

Then import:

```dart
import 'package:offline_first_image_box/offline_first_image_box.dart';
```

---

## ⚡ Quick Start

Load an offline-first image in under 15 lines of code:

```dart
OfflineFirstImageBox(
  imageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
  width: 250,
  height: 250,
  borderRadius: BorderRadius.circular(16),
  fit: BoxFit.cover,
  placeholder: const Center(child: CircularProgressIndicator()),
  fallbackAsset: 'assets/images/fallback.png',
)
```

---

## 📖 Advanced Usage & Examples

### 1. Network-First Strategy with Custom Exponential Retry

```dart
OfflineFirstImageBox(
  imageUrl: 'https://api.myapp.com/user/avatar.jpg',
  cacheRule: CacheRule.networkFirst,
  retryPolicy: const RetryPolicy(
    maxRetries: 4,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 8),
    exponentialBackoff: true,
  ),
  fadeDuration: const Duration(milliseconds: 400),
  onLoaded: (source) {
    print('Image loaded from source: ${source.name}'); // 'network' or 'cache'
  },
)
```

### 2. Manual Cache Invalidation or Pre-caching

```dart
// Check if an image is cached:
final isCached = await OfflineImageCacheManager.instance.has('my_image_url');

// Evict a specific image:
await OfflineImageCacheManager.instance.evict('my_image_url');

// Clear entire image cache:
await OfflineImageCacheManager.instance.clear();
```

---

## 🛠️ Properties Table

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `imageUrl` | `String` | *Required* | Remote image URL to download and cache. |
| `cacheKey` | `String?` | `imageUrl` | Optional custom cache key. |
| `width` | `double?` | `null` | Width of the image container. |
| `height` | `double?` | `null` | Height of the image container. |
| `fit` | `BoxFit` | `BoxFit.cover` | How the image fits inside the bounds. |
| `borderRadius` | `BorderRadius?` | `null` | Optional border radius for rounded corners. |
| `placeholder` | `Widget?` | `CircularProgressIndicator` | Placeholder widget displayed while resolving. |
| `fallbackAsset` | `String?` | `null` | Emergency local asset fallback path. |
| `cacheRule` | `CacheRule` | `CacheRule.cacheFirst` | Strategy (`cacheFirst`, `networkFirst`, `cacheOnly`, `networkOnly`). |
| `retryPolicy` | `RetryPolicy` | `RetryPolicy()` | Auto-retry backoff policy configuration. |
| `ttl` | `Duration?` | `null` | Time-to-live expiration duration for cached copy. |
| `fadeDuration` | `Duration` | `300ms` | Cross-fade animation duration. |
| `reloadOnErrorTap` | `bool` | `true` | Whether tapping the error view triggers a reload. |
| `onLoaded` | `ValueChanged<ImageSource>?` | `null` | Callback reporting the resolved origin tier. |
| `onError` | `ValueChanged<Object>?` | `null` | Callback reporting failure details. |

---

## 🎬 Preview & Demo

```
+-------------------------------------------------------------+
|                  [ offline_first_image_box ]                |
|                                                             |
|   ONLINE (First Load)         OFFLINE / RESTART             |
|   +---------------------+     +---------------------+       |
|   | 🔄 Downloading...   |     | ⚡ Instant Cached   |       |
|   |   (Cross-fades in)  |     |   (Zero Network)    |       |
|   +---------------------+     +---------------------+       |
|                                                             |
|   NETWORK DROP RECOVERY       MULTI-TIER FALLBACK           |
|   +---------------------+     +---------------------+       |
|   | ⏳ Auto-retrying    |     | 📦 Asset Fallback   |       |
|   |   (Exp. Backoff)    | ➔  |   (No Red Errors!)  |       |
|   +---------------------+     +---------------------+       |
+-------------------------------------------------------------+
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to open an issue or pull request on [GitHub](https://github.com/BalochCodes/offline_first_image_box).

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

Developed with ❤️ by **Shahzain Baloch** ([BalochCodes](https://github.com/BalochCodes)).
