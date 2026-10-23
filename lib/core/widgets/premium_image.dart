import 'package:flutter/material.dart';

class PremiumImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final IconData? fallbackIcon;

  const PremiumImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16,
    this.fallbackIcon,
  });

  bool get _isAsset => imageUrl.startsWith('assets/');
  bool get _isNetwork => imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.isEmpty) return _buildFallback();

    if (_isAsset) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (_isNetwork) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      color: Colors.grey[100],
      child: Icon(fallbackIcon ?? Icons.menu_book_rounded, color: Colors.grey[400], size: width * 0.4),
    );
  }
}
