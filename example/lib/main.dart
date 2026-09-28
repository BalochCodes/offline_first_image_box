import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:offline_first_image_box/offline_first_image_box.dart';

void main() {
  runApp(const OfflineImageDemoApp());
}

class OfflineImageDemoApp extends StatelessWidget {
  const OfflineImageDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline First Image Box Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ImageDemoHomePage(),
    );
  }
}

class ImageDemoHomePage extends StatefulWidget {
  const ImageDemoHomePage({super.key});

  @override
  State<ImageDemoHomePage> createState() => _ImageDemoHomePageState();
}

class _ImageDemoHomePageState extends State<ImageDemoHomePage> {
  bool _simulateOffline = false;
  final Map<String, ImageSource> _sourceMap = {};

  // Standard 67-byte valid 1x1 PNG image
  static final Uint8List _samplePng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  final List<String> _demoUrls = [
    'https://images.unsplash.com/photo-1',
    'https://images.unsplash.com/photo-2',
    'https://images.unsplash.com/photo-3',
    'https://images.unsplash.com/photo-4',
  ];

  @override
  void initState() {
    super.initState();
    _configureMockFetcher();
  }

  void _configureMockFetcher() {
    ImageLoader.setCustomNetworkFetcher((uri) async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (_simulateOffline) {
        throw Exception('Network unreachable (Simulated Offline Mode)');
      }
      return _samplePng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline-First Image Loader'),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Cache',
            onPressed: () async {
              await OfflineImageCacheManager.instance.clear();
              setState(() {
                _sourceMap.clear();
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared!')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Toggle Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _simulateOffline
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF0FDF4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _simulateOffline
                          ? Icons.wifi_off_rounded
                          : Icons.wifi_rounded,
                      color: _simulateOffline
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _simulateOffline ? 'Network: OFFLINE' : 'Network: ONLINE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _simulateOffline
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          _simulateOffline
                              ? 'Cached images will load; new ones will fail.'
                              : 'All images fetch from network or cache.',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _simulateOffline,
                  activeTrackColor: const Color(0xFFDC2626),
                  onChanged: (val) {
                    setState(() {
                      _simulateOffline = val;
                      _configureMockFetcher();
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Grid of Images
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.88,
              ),
              itemCount: _demoUrls.length,
              itemBuilder: (context, index) {
                final url = _demoUrls[index];
                final source = _sourceMap[url];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: OfflineFirstImageBox(
                          key: ValueKey('$url-$_simulateOffline'),
                          imageUrl: url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          onLoaded: (src) {
                            setState(() {
                              _sourceMap[url] = src;
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Photo #${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (source != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: source == ImageSource.cache
                                      ? Colors.amber.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  source.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: source == ImageSource.cache
                                        ? Colors.amber.shade900
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
