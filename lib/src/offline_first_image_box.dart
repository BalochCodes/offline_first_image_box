import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'cache_policy.dart';
import 'image_cache_store.dart';
import 'image_loader.dart';

/// A resilient, offline-first image widget designed for unstable network conditions.
///
/// Features two-tier progressive rendering, persistent local caching, automatic
/// exponential retry on network timeouts, and multi-tier fallbacks (network ➔ cache ➔ asset ➔ error).
class OfflineFirstImageBox extends StatefulWidget {
  /// The remote image URL to load.
  final String imageUrl;

  /// Optional custom cache key. Defaults to [imageUrl].
  final String? cacheKey;

  /// Width of the image container.
  final double? width;

  /// Height of the image container.
  final double? height;

  /// How the image should be inscribed into the box. Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Corner radius of the image card.
  final BorderRadius? borderRadius;

  /// Placeholder widget displayed while loading or before resolution.
  final Widget? placeholder;

  /// Bundled asset path used as emergency fallback when both network and cache fail.
  final String? fallbackAsset;

  /// Caching priority strategy (cache-first or network-first). Defaults to [CacheRule.cacheFirst].
  final CacheRule cacheRule;

  /// Automatic retry policy for failed network downloads.
  final RetryPolicy retryPolicy;

  /// Time-to-live expiration duration for the cached entry.
  final Duration? ttl;

  /// Duration of the cross-fade transition from placeholder to loaded image. Defaults to 300ms.
  final Duration fadeDuration;

  /// Animation curve for the cross-fade transition. Defaults to [Curves.easeOut].
  final Curve fadeCurve;

  /// Whether tapping on an error state automatically re-triggers the load attempt. Defaults to true.
  final bool reloadOnErrorTap;

  /// Custom builder for the loading state.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Custom builder for the error state.
  final Widget Function(BuildContext context, Object? error, VoidCallback reload)? errorBuilder;

  /// Callback invoked when an image successfully resolves, notifying the source tier.
  final ValueChanged<ImageSource>? onLoaded;

  /// Callback invoked if all resolution tiers fail.
  final ValueChanged<Object>? onError;

  /// Optional specific cache store instance. Defaults to [OfflineImageCacheManager.instance.store].
  final ImageCacheStore? cacheStore;

  /// Creates an [OfflineFirstImageBox].
  const OfflineFirstImageBox({
    super.key,
    required this.imageUrl,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.fallbackAsset,
    this.cacheRule = CacheRule.cacheFirst,
    this.retryPolicy = const RetryPolicy(),
    this.ttl,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.fadeCurve = Curves.easeOut,
    this.reloadOnErrorTap = true,
    this.loadingBuilder,
    this.errorBuilder,
    this.onLoaded,
    this.onError,
    this.cacheStore,
  });

  @override
  State<OfflineFirstImageBox> createState() => _OfflineFirstImageBoxState();
}

class _OfflineFirstImageBoxState extends State<OfflineFirstImageBox> {
  bool _isLoading = true;
  Uint8List? _resolvedBytes;
  ImageSource _source = ImageSource.none;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant OfflineFirstImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.cacheKey != widget.cacheKey ||
        oldWidget.cacheRule != widget.cacheRule) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ImageLoader.load(
      imageUrl: widget.imageUrl,
      cacheKey: widget.cacheKey,
      rule: widget.cacheRule,
      retryPolicy: widget.retryPolicy,
      fallbackAsset: widget.fallbackAsset,
      ttl: widget.ttl,
      cacheStore: widget.cacheStore,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _resolvedBytes = result.bytes;
      _source = result.source;
      _error = result.error;
    });

    if (result.isSuccess) {
      widget.onLoaded?.call(result.source);
    } else if (result.error != null) {
      widget.onError?.call(result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading && _resolvedBytes == null) {
      content = widget.loadingBuilder?.call(context) ?? _buildDefaultPlaceholder();
    } else if (_resolvedBytes != null) {
      content = Image.memory(
        _resolvedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else {
      content = widget.errorBuilder?.call(context, _error, _loadImage) ??
          _buildDefaultError();
    }

    // Wrap in animated switcher for progressive cross-fade
    content = AnimatedSwitcher(
      duration: widget.fadeDuration,
      switchInCurve: widget.fadeCurve,
      switchOutCurve: widget.fadeCurve,
      child: KeyedSubtree(
        key: ValueKey('img_${_source.name}_${_isLoading}_${_resolvedBytes != null}'),
        child: content,
      ),
    );

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }

  Widget _buildDefaultPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    final errorWidget = Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(4),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 24),
              const SizedBox(height: 2),
              Text(
                widget.reloadOnErrorTap ? 'Offline / Error (Tap to retry)' : 'Failed to load',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.reloadOnErrorTap) {
      return GestureDetector(
        key: const ValueKey('reload_error_tap'),
        onTap: _loadImage,
        behavior: HitTestBehavior.opaque,
        child: errorWidget,
      );
    }

    return errorWidget;
  }
}
