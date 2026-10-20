import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../video_selection/presentation/video_selection_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../comparison/presentation/comparison_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _currentApiUrl = ApiConstants.baseUrl;
  bool _checkingHealth = false;
  bool? _isBackendOnline;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _checkingHealth = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.checkHealth();
      setState(() {
        _isBackendOnline = res['status'] == 'healthy';
        _checkingHealth = false;
      });
    } catch (_) {
      setState(() {
        _isBackendOnline = false;
        _checkingHealth = false;
      });
    }
  }

  void _showApiSettingsDialog() {
    final controller = TextEditingController(text: _currentApiUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend API Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or enter backend API base URL:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://127.0.0.1:8000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Presets:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Localhost (8000)'),
                  onPressed: () => controller.text = ApiConstants.localhostUrl,
                ),
                ActionChip(
                  label: const Text('Android Emulator'),
                  onPressed: () => controller.text = ApiConstants.emulatorUrl,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _currentApiUrl = newUrl;
                  ApiConstants.baseUrl = newUrl;
                });
                ref.read(apiClientProvider).updateBaseUrl(newUrl);
                _checkBackendHealth();
              }
              Navigator.pop(context);
            },
            child: const Text('Save & Test'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, color: AppColors.primaryAccent),
            const SizedBox(width: 10),
            const Text(
              'VidForensic',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configure Backend URL',
            onPressed: _showApiSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              ForensicCard(
                borderColor: AppColors.primaryAccent.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIDFORENSIC v1.0',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        // Connection Status Chip
                        GestureDetector(
                          onTap: _checkBackendHealth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isBackendOnline == true
                                  ? AppColors.statusSuccess.withValues(alpha: 0.15)
                                  : AppColors.statusError.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: _isBackendOnline == true
                                      ? AppColors.statusSuccess
                                      : AppColors.statusError,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _checkingHealth
                                      ? 'Checking...'
                                      : _isBackendOnline == true
                                          ? 'Backend Connected'
                                          : 'Backend Offline',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isBackendOnline == true
                                        ? AppColors.statusSuccess
                                        : AppColors.statusError,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Video Forensic Analyzer',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyze videos for frame anomalies, manipulation indicators, AI-like forensic signals and generate formal forensic reports.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CTA Buttons
              AppButton(
                label: 'Analyze New Video',
                icon: Icons.video_call,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VideoSelectionScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              AppButton(
                label: 'Video Comparison Mode',
                icon: Icons.compare_arrows,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComparisonScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              AppButton(
                label: 'Analysis History',
                icon: Icons.history,
                isSecondary: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Capabilities Section
              Text(
                'FORENSIC CAPABILITIES',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureItem(
                context,
                icon: Icons.analytics_outlined,
                title: 'Frame Analysis',
                subtitle: 'Detect freeze frames, duplicate sequences, missing frames, and decoding errors.',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.search,
                title: 'Manipulation Detection',
                subtitle: 'Identify visual temporal anomalies, splice candidates, and scene edits.',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.memory_outlined,
                title: 'AI Forensic Analysis',
                subtitle: 'Spectral FFT, residual noise PRNU, optical flow, and face artifact signals.',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.merge_type_outlined,
                title: 'Evidence Fusion',
                subtitle: 'Multi-detector scoring, confidence calibration, and standardized evidence cards.',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.picture_as_pdf_outlined,
                title: 'PDF Forensic Reports',
                subtitle: 'Generate publication-ready PDF audit reports with summary charts and hashes.',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.compare_arrows,
                title: 'Video Comparison Mode',
                subtitle: 'Dual-video timeline alignment, synchronized playback, and frame-level difference heatmaps.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ForensicCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppColors.primaryAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
