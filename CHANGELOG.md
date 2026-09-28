## 0.0.1

* Initial release of `offline_first_image_box`.
* Resilient, bulletproof image loading widget designed for unstable or offline network conditions.
* Two-tier progressive rendering with smooth cross-fade from low-res blur/placeholder to high-res image.
* Multi-tier fallback pipeline: network image -> local cached disk copy -> bundled asset fallback -> custom error/retry widget.
* Intelligent offline cache persistence with configurable TTL and max entries eviction.
* Auto-retry mechanism with exponential backoff on network failures.
* Manual reload-on-tap triggers and customizable loading/error builders.
