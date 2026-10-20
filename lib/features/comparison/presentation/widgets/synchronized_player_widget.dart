import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/forensic_card.dart';
import '../../models/comparison_models.dart';

enum ComparisonViewMode {
  sideBySide,
  blendedOverlay,
  differenceView,
}

class SynchronizedPlayerWidget extends StatefulWidget {
  final File fileA;
  final File fileB;
  final double timeOffset; // seconds
  final List<SuspiciousInterval> suspiciousIntervals;
  final String? evidenceBaseUrl;
  final int? activeIntervalIndex;
  final Function(double timestamp)? onSeek;

  const SynchronizedPlayerWidget({
    super.key,
    required this.fileA,
    required this.fileB,
    this.timeOffset = 0.0,
    this.suspiciousIntervals = const [],
    this.evidenceBaseUrl,
    this.activeIntervalIndex,
    this.onSeek,
  });

  @override
  State<SynchronizedPlayerWidget> createState() =>
      _SynchronizedPlayerWidgetState();
}

class _SynchronizedPlayerWidgetState extends State<SynchronizedPlayerWidget> {
  VideoPlayerController? _controllerA;
  VideoPlayerController? _controllerB;
  bool _initialized = false;
  bool _isPlaying = false;

  ComparisonViewMode _viewMode = ComparisonViewMode.sideBySide;
  double _blendOpacity = 0.5; // 0.0 = Video A only, 1.0 = Video B only
  double _zoomScale = 1.0; // 1.0 = fit, 1.5x, 2.0x
  double _playbackSpeed = 1.0;

  Duration _currentPosA = Duration.zero;
  Duration _totalDurationA = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initDualPlayers();
  }

  @override
  void didUpdateWidget(covariant SynchronizedPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIntervalIndex != null &&
        widget.activeIntervalIndex != oldWidget.activeIntervalIndex) {
      _jumpToInterval(widget.activeIntervalIndex!);
    }
  }

  Future<void> _initDualPlayers() async {
    _disposeControllers();

    _controllerA = VideoPlayerController.file(widget.fileA);
    _controllerB = VideoPlayerController.file(widget.fileB);

    try {
      await Future.wait([
        _controllerA!.initialize(),
        _controllerB!.initialize(),
      ]);

      _totalDurationA = _controllerA!.value.duration;

      _controllerA!.addListener(_onControllerTick);

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _initialized = false;
        });
      }
    }
  }

  void _onControllerTick() {
    if (_controllerA != null && mounted) {
      setState(() {
        _currentPosA = _controllerA!.value.position;
        _isPlaying = _controllerA!.value.isPlaying;
      });
    }
  }

  void _disposeControllers() {
    _controllerA?.removeListener(_onControllerTick);
    _controllerA?.dispose();
    _controllerB?.dispose();
    _controllerA = null;
    _controllerB = null;
    _initialized = false;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_initialized || _controllerA == null || _controllerB == null) return;

    if (_isPlaying) {
      await Future.wait([
        _controllerA!.pause(),
        _controllerB!.pause(),
      ]);
      setState(() => _isPlaying = false);
    } else {
      // Sync B position before play
      final targetB = _calcTargetB(_currentPosA);
      await _controllerB!.seekTo(targetB);
      await Future.wait([
        _controllerA!.setPlaybackSpeed(_playbackSpeed),
        _controllerB!.setPlaybackSpeed(_playbackSpeed),
      ]);
      await Future.wait([
        _controllerA!.play(),
        _controllerB!.play(),
      ]);
      setState(() => _isPlaying = true);
    }
  }

  Duration _calcTargetB(Duration posA) {
    final double secsA = posA.inMilliseconds / 1000.0;
    final double secsB = (secsA + widget.timeOffset).clamp(0.0, 3600.0);
    return Duration(milliseconds: (secsB * 1000).toInt());
  }

  Future<void> _seekBoth(Duration posA) async {
    if (!_initialized || _controllerA == null || _controllerB == null) return;

    final targetB = _calcTargetB(posA);
    await Future.wait([
      _controllerA!.seekTo(posA),
      _controllerB!.seekTo(targetB),
    ]);

    setState(() {
      _currentPosA = posA;
    });

    if (widget.onSeek != null) {
      widget.onSeek!(posA.inMilliseconds / 1000.0);
    }
  }

  Future<void> _stepFrame(int direction) async {
    if (!_initialized || _controllerA == null) return;
    await _controllerA!.pause();
    await _controllerB?.pause();

    // ~33ms step per frame at 30fps
    final currentMs = _controllerA!.value.position.inMilliseconds;
    final newMs = (currentMs + (direction * 33)).clamp(0, _totalDurationA.inMilliseconds);
    await _seekBoth(Duration(milliseconds: newMs));
  }

  void _jumpToInterval(int intervalIndex) {
    final interval = widget.suspiciousIntervals.firstWhere(
      (i) => i.intervalIndex == intervalIndex,
      orElse: () => widget.suspiciousIntervals.first,
    );
    final targetSecs = interval.startTimeA;
    _seekBoth(Duration(milliseconds: (targetSecs * 1000).toInt()));
  }

  void _setSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    if (_initialized) {
      await Future.wait([
        _controllerA!.setPlaybackSpeed(speed),
        _controllerB!.setPlaybackSpeed(speed),
      ]);
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$mins:$secs.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSecsA = _currentPosA.inMilliseconds / 1000.0;
    final currentSecsB = currentSecsA + widget.timeOffset;

    // Check if current timestamp falls within a suspicious interval
    final currentInterval = widget.suspiciousIntervals.cast<SuspiciousInterval?>().firstWhere(
          (i) => i != null && currentSecsA >= i.startTimeA && currentSecsA <= i.endTimeA,
          orElse: () => null,
        );

    return ForensicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync_alt, color: AppColors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SYNCHRONIZED FORENSIC VIEWER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              // View Mode Selector
              SegmentedButton<ComparisonViewMode>(
                segments: const [
                  ButtonSegment(
                    value: ComparisonViewMode.sideBySide,
                    icon: Icon(Icons.view_column_outlined, size: 16),
                    label: Text('Side-by-Side', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: ComparisonViewMode.blendedOverlay,
                    icon: Icon(Icons.layers_outlined, size: 16),
                    label: Text('Blend Overlay', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: ComparisonViewMode.differenceView,
                    icon: Icon(Icons.gradient_outlined, size: 16),
                    label: Text('Difference', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (set) {
                  setState(() => _viewMode = set.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Viewport
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 320,
              width: double.infinity,
              color: Colors.black,
              child: _initialized && _controllerA != null && _controllerB != null
                  ? _buildViewportContent(currentInterval)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Initializing synchronized video decoders...',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Viewport Modifiers (Opacity Slider for Blend Mode, Zoom Controls)
          if (_viewMode == ComparisonViewMode.blendedOverlay) ...[
            Row(
              children: [
                const Text('Ref (A)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryCyan)),
                Expanded(
                  child: Slider(
                    value: _blendOpacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: 'Suspected: ${(_blendOpacity * 100).toInt()}%',
                    onChanged: (val) {
                      setState(() => _blendOpacity = val);
                    },
                  ),
                ),
                const Text('Susp (B)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warningOrange)),
                const SizedBox(width: 8),
                Text('${(_blendOpacity * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ],
            ),
          ],

          // Synchronized Seek Slider
          if (_initialized && _totalDurationA.inMilliseconds > 0) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _currentPosA.inMilliseconds
                    .toDouble()
                    .clamp(0.0, _totalDurationA.inMilliseconds.toDouble()),
                min: 0.0,
                max: _totalDurationA.inMilliseconds.toDouble(),
                onChanged: (ms) {
                  _seekBoth(Duration(milliseconds: ms.toInt()));
                },
              ),
            ),
          ],

          // Playback Control Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timestamp display
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ref: ${_formatDuration(_currentPosA)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Susp: ${_formatDuration(Duration(milliseconds: (currentSecsB * 1000).toInt()))}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${_formatDuration(_totalDurationA)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              // Player buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 20),
                    tooltip: 'Step Backward (1 frame)',
                    onPressed: () => _stepFrame(-1),
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: AppColors.primaryAccent,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 20),
                    tooltip: 'Step Forward (1 frame)',
                    onPressed: () => _stepFrame(1),
                  ),
                ],
              ),

              // Speed & Zoom controls
              Row(
                children: [
                  // Playback speed
                  PopupMenuButton<double>(
                    tooltip: 'Playback Speed',
                    onSelected: _setSpeed,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 0.25, child: Text('0.25x')),
                      const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
                      const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Zoom toggle
                  IconButton(
                    icon: Icon(
                      _zoomScale > 1.0 ? Icons.zoom_out : Icons.zoom_in,
                      size: 20,
                    ),
                    tooltip: _zoomScale > 1.0 ? 'Reset Zoom' : 'Zoom In (1.5x)',
                    onPressed: () {
                      setState(() {
                        _zoomScale = _zoomScale > 1.0 ? 1.0 : 1.5;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),

          // Suspicious Interval Anomaly Alert Banner when playing through an anomalous point
          if (currentInterval != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SUSPICIOUS INTERVAL [${currentInterval.intervalId}]: '
                      'SSIM drop to ${currentInterval.minSsim.toStringAsFixed(3)} '
                      '(Max Diff: ${currentInterval.maxDifference.toStringAsFixed(3)}) — ${currentInterval.explanation}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewportContent(SuspiciousInterval? currentInterval) {
    Widget content;

    switch (_viewMode) {
      case ComparisonViewMode.sideBySide:
        content = Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controllerA!.value.aspectRatio,
                    child: VideoPlayer(_controllerA!),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.secondaryCyan, width: 1),
                      ),
                      child: const Text('REF (A)',
                          style: TextStyle(color: AppColors.secondaryCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 2, color: Colors.grey[800]),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controllerB!.value.aspectRatio,
                    child: VideoPlayer(_controllerB!),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.warningOrange, width: 1),
                      ),
                      child: const Text('SUSP (B)',
                          style: TextStyle(color: AppColors.warningOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case ComparisonViewMode.blendedOverlay:
        content = Stack(
          alignment: Alignment.center,
          children: [
            // Video A at base
            AspectRatio(
              aspectRatio: _controllerA!.value.aspectRatio,
              child: VideoPlayer(_controllerA!),
            ),
            // Video B overlaid with opacity
            Opacity(
              opacity: _blendOpacity,
              child: AspectRatio(
                aspectRatio: _controllerB!.value.aspectRatio,
                child: VideoPlayer(_controllerB!),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BLENDED OVERLAY (${((1 - _blendOpacity) * 100).toInt()}% Ref / ${(_blendOpacity * 100).toInt()}% Susp)',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
        break;

      case ComparisonViewMode.differenceView:
        if (currentInterval != null &&
            currentInterval.evidenceFiles.containsKey('diff_heatmap') &&
            widget.evidenceBaseUrl != null) {
          final diffUrl =
              '${widget.evidenceBaseUrl}/${currentInterval.evidenceFiles['diff_heatmap']}';
          content = Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                diffUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackDiffView(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FORENSIC HEATMAP [${currentInterval.intervalId}] — SSIM: ${currentInterval.minSsim.toStringAsFixed(3)}',
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        } else {
          content = _buildFallbackDiffView();
        }
        break;
    }

    if (_zoomScale > 1.0) {
      return InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 1.0,
        maxScale: 3.0,
        child: content,
      );
    }

    return content;
  }

  Widget _buildFallbackDiffView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.difference_outlined, size: 40, color: AppColors.primaryAccent),
          const SizedBox(height: 8),
          const Text(
            'Difference Heatmap View',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Scrub or jump to a suspicious interval on the timeline to view difference heatmaps.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
