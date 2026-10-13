import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../providers/upload_provider.dart';
import '../../analysis/presentation/analysis_screen.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUpload();
    });
  }

  Future<void> _startUpload() async {
    final jobId = await ref.read(uploadProvider.notifier).uploadSelectedVideo();
    if (jobId != null && mounted) {
      // Navigate to Analysis Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(jobId: jobId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final theme = Theme.of(context);
    final percentage = (uploadState.progress * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploading Video'),
        automaticallyImplyLeading: !uploadState.isUploading,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ForensicCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (uploadState.error == null) ...[
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 64,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Uploading ${uploadState.videoName ?? "Video"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sending file to VidForensic engine...',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: uploadState.progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          uploadState.progress >= 1.0 ? 'Upload complete!' : 'Uploading...',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.statusError,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.statusError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      uploadState.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Back',
                            isSecondary: true,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Retry Upload',
                            icon: Icons.refresh,
                            onPressed: _startUpload,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
