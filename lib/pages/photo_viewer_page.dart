import 'package:flutter/material.dart';

class PhotoViewerPage extends StatefulWidget {
  final String imageUrl;
  final String productName;

  const PhotoViewerPage({
    required this.imageUrl,
    required this.productName,
    super.key,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  double _rotationAngle = 0;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  void _rotateImage() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  void _resetImage() {
    setState(() {
      _rotationAngle = 0;
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'إعادة تعيين',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetImage,
            ),
          ),
          Tooltip(
            message: 'تدوير (90°)',
            child: IconButton(
              icon: const Icon(Icons.rotate_right),
              onPressed: _rotateImage,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _offset += details.delta;
                });
              },
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.5,
                maxScale: 3.0,
                onInteractionUpdate: (details) {
                  setState(() {
                    _scale = details.scale;
                  });
                },
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateZ(_rotationAngle * 3.14159 / 180),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 100),
                            SizedBox(height: 16),
                            Text('لم تتمكن من تحميل الصورة'),
                          ],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('التحكم بالصورة', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'الدوران: ${_rotationAngle.toInt()}°',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة تعيين'),
                        onPressed: _resetImage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.rotate_right),
                        label: const Text('تدوير'),
                        onPressed: _rotateImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'استخدم أصابعك للتكبير/التصغير والحركة على الصورة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
