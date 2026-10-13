import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FramePreviewWidget extends StatelessWidget {
  final String? previousFrameUrl;
  final String? evidenceFrameUrl;
  final String? nextFrameUrl;
  final int? frameNumber;
  final double? timestamp;

  const FramePreviewWidget({
    super.key,
    this.previousFrameUrl,
    this.evidenceFrameUrl,
    this.nextFrameUrl,
    this.frameNumber,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAnyImage = (evidenceFrameUrl != null && evidenceFrameUrl!.isNotEmpty) ||
        (previousFrameUrl != null && previousFrameUrl!.isNotEmpty) ||
        (nextFrameUrl != null && nextFrameUrl!.isNotEmpty);

    if (!hasAnyImage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Frame preview unavailable',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (frameNumber != null || timestamp != null) ...[
          Text(
            'FRAME PREVIEW ${frameNumber != null ? '(Frame #$frameNumber)' : ''} ${timestamp != null ? 'at ${timestamp!.toStringAsFixed(2)}s' : ''}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (previousFrameUrl != null && previousFrameUrl!.isNotEmpty)
              Expanded(child: _buildFrameCard('Prev Frame', previousFrameUrl!)),
            if (previousFrameUrl != null && previousFrameUrl!.isNotEmpty)
              const SizedBox(width: 8),
            if (evidenceFrameUrl != null && evidenceFrameUrl!.isNotEmpty)
              Expanded(child: _buildFrameCard('Evidence Frame', evidenceFrameUrl!, isTarget: true)),
            if (nextFrameUrl != null && nextFrameUrl!.isNotEmpty)
              const SizedBox(width: 8),
            if (nextFrameUrl != null && nextFrameUrl!.isNotEmpty)
              Expanded(child: _buildFrameCard('Next Frame', nextFrameUrl!)),
          ],
        ),
      ],
    );
  }

  Widget _buildFrameCard(String label, String url, {bool isTarget = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTarget ? AppColors.primaryAccent : Colors.grey.withValues(alpha: 0.3),
          width: isTarget ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            width: double.infinity,
            color: isTarget ? AppColors.primaryAccent.withValues(alpha: 0.2) : Colors.black12,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                color: isTarget ? AppColors.primaryAccent : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: url.startsWith('http://') || url.startsWith('https://')
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                    )
                  : Image.file(
                      File(url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Text(
          'Frame preview unavailable',
          style: TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
