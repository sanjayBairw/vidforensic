import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../video_selection/presentation/video_selection_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../comparison/presentation/comparison_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';

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
        _isBackendOnline = res['status'] == 'healthy' || res['status'] == 'ok';
        _checkingHealth = false;
      });
    } catch (_) {
      setState(() {
        _isBackendOnline = false;
        _checkingHealth = false;
      });
    }
  }

  void _showThemeDialog() {
    final currentMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.palette_outlined, color: AppColors.primaryAccent),
            SizedBox(width: 10),
            Text('App Appearance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: context,
              title: 'Light Mode (Default)',
              subtitle: 'Clean, bright forensic workstation',
              icon: Icons.light_mode,
              iconColor: Colors.orange,
              mode: ThemeMode.light,
              currentMode: currentMode,
            ),
            _buildThemeOption(
              context: context,
              title: 'Dark Mode',
              subtitle: 'Deep slate low-light workstation',
              icon: Icons.dark_mode,
              iconColor: Colors.indigo,
              mode: ThemeMode.dark,
              currentMode: currentMode,
            ),
            _buildThemeOption(
              context: context,
              title: 'System Default',
              subtitle: 'Matches your device system setting',
              icon: Icons.settings_brightness,
              iconColor: Colors.teal,
              mode: ThemeMode.system,
              currentMode: currentMode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF))
        : Colors.transparent;
    final borderColor = isSelected
        ? AppColors.primaryAccent
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primaryAccent, size: 20)
              : null,
          onTap: () {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showApiSettingsDialog() {
    final controller = TextEditingController(text: _currentApiUrl);
    final currentTheme = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THEME & APPEARANCE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 16),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 16),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_brightness, size: 16),
                    label: Text('Auto'),
                  ),
                ],
                selected: {currentTheme},
                onSelectionChanged: (newSelection) {
                  ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'BACKEND API ENDPOINT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'https://vidforensicback.onrender.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Presets:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Render Cloud (Default)'),
                    onPressed: () => controller.text = ApiConstants.productionUrl,
                  ),
                  ActionChip(
                    label: const Text('Localhost (8000)'),
                    onPressed: () => controller.text = ApiConstants.localhostUrl,
                  ),
                  ActionChip(
                    label: const Text('Android / LAN'),
                    onPressed: () => controller.text = ApiConstants.emulatorUrl,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'SUPABASE AUTHENTICATION',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final auth = ref.watch(authNotifierProvider);
                  if (auth.isAuthenticated) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified, color: AppColors.statusSuccess),
                      title: Text(
                        auth.user?.email ?? 'Authenticated',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: const Text('Logged in with Supabase', style: TextStyle(fontSize: 11)),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(authNotifierProvider.notifier).signOut();
                        },
                        child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      ),
                    );
                  } else {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_off, color: Colors.grey),
                      title: const Text('Guest Mode (Not Signed In)', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Sign in to sync audits to Supabase cloud', style: TextStyle(fontSize: 11)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text('Sign In'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
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
                final formattedUrl = ApiConstants.formatBaseUrl(newUrl);
                setState(() {
                  _currentApiUrl = formattedUrl;
                  ApiConstants.baseUrl = formattedUrl;
                });
                ref.read(apiClientProvider).updateBaseUrl(formattedUrl);
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

  void _showAccountDialog() {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.primaryAccent),
            SizedBox(width: 8),
            Text('Investigator Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                user?.email ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Supabase Authenticated',
                style: TextStyle(
                  color: AppColors.statusSuccess,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 6),
            Text(
              'INVESTIGATOR ID',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              user?.id ?? 'N/A',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'AUTH PROVIDER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supabase Cloud (rsocwvpxvxgskdgpmice)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign Out'),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Successfully signed out of Supabase.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, color: AppColors.primaryAccent),
            const SizedBox(width: 10),
            Text(
              'VidForensic',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode_outlined,
              color: isDark ? Colors.amber : AppColors.lightTextPrimary,
            ),
            tooltip: 'Appearance & Theme',
            onPressed: _showThemeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & Theme',
            onPressed: _showApiSettingsDialog,
          ),
          IconButton(
            icon: Icon(
              authState.isAuthenticated ? Icons.account_circle : Icons.account_circle_outlined,
              color: authState.isAuthenticated ? AppColors.primaryAccent : null,
            ),
            tooltip: authState.isAuthenticated
                ? 'Investigator (${authState.user?.email})'
                : 'Sign In (Supabase)',
            onPressed: () {
              if (authState.isAuthenticated) {
                _showAccountDialog();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
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
                    const SizedBox(height: 14),
                    // Supabase Authentication Status Strip
                    if (authState.isAuthenticated) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.highlight(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, size: 16, color: AppColors.primaryAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Investigator: ${authState.user?.email}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: _showAccountDialog,
                              child: const Text(
                                'Account',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_queue, size: 16, color: AppColors.textSecondary(context)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Supabase Cloud: Guest Mode',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
