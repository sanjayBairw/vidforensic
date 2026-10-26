import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/forensic_card.dart';

class VideoSelectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final File? file;
  final String? filename;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const VideoSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.file,
    required this.filename,
    required this.onPick,
    required this.onRemove,
  });

  @override
  State<VideoSelectionCard> createState() => _VideoSelectionCardState();
}

class _VideoSelectionCardState extends State<VideoSelectionCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitController();
  }

  @override
  void didUpdateWidget(covariant VideoSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file?.path != oldWidget.file?.path) {
      _disposeController();
      _checkInitController();
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialized = false;
  }

  void _checkInitController() async {
    if (widget.file != null && widget.file!.existsSync()) {
      _controller = VideoPlayerController.file(widget.file!);
      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      } catch (_) {
        // Fallback gracefully if codec unsupported by device hardware decoder
        if (mounted) {
          setState(() {
            _initialized = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = widget.file != null;

    return ForensicCard(
      borderColor: widget.accentColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (hasFile)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove Video',
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),

          // Content Box
          if (!hasFile)
            InkWell(
              onTap: widget.onPick,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 44,
                      color: widget.accentColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Select Video File',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: widget.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MP4, AVI, MOV, MKV, WEBM (Max 500 MB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Video Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 160,
                width: double.infinity,
                color: Colors.black,
                child: _initialized && _controller != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                          IconButton(
                            iconSize: 42,
                            icon: Icon(
                              _controller!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                            },
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_file,
                              size: 40, color: widget.accentColor),
                          const SizedBox(height: 6),
                          const Text(
                            'Video Ready for Analysis',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Metadata Chips
            _buildMetaRow(context, 'Filename:', widget.filename ?? widget.file!.path.split(Platform.pathSeparator).last),
            _buildMetaRow(context, 'File Size:', Formatters.formatFileSize(widget.file!.lengthSync())),
            _buildMetaRow(context, 'Format:', widget.file!.path.split('.').last.toUpperCase()),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Replace', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.accentColor,
                      side: BorderSide(color: widget.accentColor.withValues(alpha: 0.5)),
                    ),
                    onPressed: widget.onPick,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryTextColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
