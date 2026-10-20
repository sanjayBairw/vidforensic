import 'dart:io';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    final bool hasAnyImage = (evidenceFrameUrl != null && evidenceFrameUrl!.isNotEmpty) ||
        (previousFrameUrl != null && previousFrameUrl!.isNotEmpty) ||
        (nextFrameUrl != null && nextFrameUrl!.isNotEmpty);

    if (!hasAnyImage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 20, color: secondaryTextColor),
            const SizedBox(width: 8),
            Text(
              'Frame preview unavailable',
              style: TextStyle(fontSize: 12, color: secondaryTextColor, fontStyle: FontStyle.italic),
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (previousFrameUrl != null && previousFrameUrl!.isNotEmpty)
              Expanded(child: _buildFrameCard(context, 'Prev Frame', previousFrameUrl!)),
            if (previousFrameUrl != null && previousFrameUrl!.isNotEmpty)
              const SizedBox(width: 8),
            if (evidenceFrameUrl != null && evidenceFrameUrl!.isNotEmpty)
              Expanded(child: _buildFrameCard(context, 'Evidence Frame', evidenceFrameUrl!, isTarget: true)),
            if (nextFrameUrl != null && nextFrameUrl!.isNotEmpty)
              const SizedBox(width: 8),
            if (nextFrameUrl != null && nextFrameUrl!.isNotEmpty)
              Expanded(child: _buildFrameCard(context, 'Next Frame', nextFrameUrl!)),
          ],
        ),
      ],
    );
  }

  Widget _buildFrameCard(BuildContext context, String label, String url, {bool isTarget = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTarget ? primary : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
          width: isTarget ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: double.infinity,
            color: isTarget ? primary.withValues(alpha: 0.12) : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9)),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isTarget ? FontWeight.bold : FontWeight.w500,
                color: isTarget ? primary : secondaryTextColor,
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
                      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(isDark, secondaryTextColor),
                    )
                  : Image.file(
                      File(url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(isDark, secondaryTextColor),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(bool isDark, Color secondaryColor) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          'Frame preview unavailable',
          style: TextStyle(fontSize: 10, color: secondaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
