import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../upload/providers/upload_provider.dart';
import '../../upload/presentation/upload_screen.dart';

class VideoSelectionScreen extends ConsumerStatefulWidget {
  const VideoSelectionScreen({super.key});

  @override
  ConsumerState<VideoSelectionScreen> createState() => _VideoSelectionScreenState();
}

class _VideoSelectionScreenState extends ConsumerState<VideoSelectionScreen> {
  VideoPlayerController? _videoPlayerController;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _initVideoPlayer(File file) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(file);
    try {
      await _videoPlayerController!.initialize();
      setState(() {});
    } catch (_) {
      // Ignore preview failure if codec not supported locally
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    final file = uploadState.selectedFile;

    if (file != null && _videoPlayerController == null) {
      _initVideoPlayer(file);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Video File'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file == null) ...[
              // Empty selection prompt
              ForensicCard(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.movie_creation_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Video Selected',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported Formats: .mp4, .mov, .mkv, .avi, .webm',
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Browse Files',
                      icon: Icons.folder_open,
                      onPressed: () {
                        ref.read(uploadProvider.notifier).pickVideo();
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Video selected details card
              ForensicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Preview Player if available
                    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoPlayerController!),
                              IconButton(
                                iconSize: 48,
                                icon: Icon(
                                  _videoPlayerController!.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_videoPlayerController!.value.isPlaying) {
                                      _videoPlayerController!.pause();
                                    } else {
                                      _videoPlayerController!.play();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_file, size: 48, color: secondaryTextColor),
                            const SizedBox(height: 8),
                            Text(
                              'Preview unavailable for this format',
                              style: TextStyle(fontSize: 12, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'FILE METADATA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: secondaryTextColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildMetaRow('Filename:', uploadState.videoName ?? file.path.split(Platform.pathSeparator).last, isDark, secondaryTextColor),
                    _buildMetaRow('File Size:', Formatters.formatFileSize(file.lengthSync()), isDark, secondaryTextColor),
                    _buildMetaRow('Extension:', file.path.split('.').last.toUpperCase(), isDark, secondaryTextColor),
                    _buildMetaRow('Full Path:', file.path, isDark, secondaryTextColor),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Choose Another',
                      isSecondary: true,
                      onPressed: () {
                        _videoPlayerController?.dispose();
                        _videoPlayerController = null;
                        ref.read(uploadProvider.notifier).pickVideo();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Start Analysis',
                      icon: Icons.upload_file,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],

            if (uploadState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  uploadState.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: secondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
