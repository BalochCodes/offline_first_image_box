import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_image_box/offline_first_image_box.dart';

void main() {
  group('OfflineFirstImageBox Widget Tests', () {
    // Standard 67-byte valid 1x1 PNG image
    final samplePng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    tearDown(() {
      ImageLoader.setCustomNetworkFetcher(null);
    });

    testWidgets('renders placeholder while loading, then displays image on success',
        (tester) async {
      ImageLoader.setCustomNetworkFetcher((uri) async {
        return samplePng;
      });

      ImageSource? resolvedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineFirstImageBox(
                imageUrl: 'https://example.com/avatar.png',
                width: 100,
                height: 100,
                placeholder: const Text('LOADING...'),
                onLoaded: (src) => resolvedSource = src,
              ),
            ),
          ),
        ),
      );

      // Verify placeholder
      expect(find.text('LOADING...'), findsOneWidget);

      // Let image load and settle cross-fade
      await tester.pumpAndSettle();

      expect(resolvedSource, ImageSource.network);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders error view on failure and allows retry tap', (tester) async {
      int attempts = 0;
      ImageLoader.setCustomNetworkFetcher((uri) async {
        attempts++;
        if (attempts == 1) {
          throw Exception('Socket timeout');
        }
        return samplePng;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineFirstImageBox(
                imageUrl: 'https://example.com/retry.png',
                width: 100,
                height: 100,
                retryPolicy: RetryPolicy(maxRetries: 0),
                reloadOnErrorTap: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First attempt failed -> shows error widget
      expect(find.byKey(const ValueKey('reload_error_tap')), findsOneWidget);
      expect(find.text('Offline / Error (Tap to retry)'), findsOneWidget);

      // Tap to reload
      await tester.tap(find.byKey(const ValueKey('reload_error_tap')));
      await tester.pumpAndSettle();

      // Second attempt succeeded -> image is visible
      expect(find.byType(Image), findsOneWidget);
      expect(attempts, 2);
    });
  });
}
