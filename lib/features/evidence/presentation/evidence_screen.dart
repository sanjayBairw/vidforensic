import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confidence_badge.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../results/models/anomaly.dart';
import '../../results/presentation/anomaly_detail_screen.dart';
import '../../results/presentation/forensic_timeline_widget.dart';
import '../../results/presentation/frame_preview_widget.dart';

class EvidenceScreen extends StatefulWidget {
  final List<Anomaly> evidenceItems;
  final double videoDuration;

  const EvidenceScreen({
    super.key,
    required this.evidenceItems,
    this.videoDuration = 0.0,
  });

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  String _selectedCategory = 'ALL';
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAnomaly(Anomaly anomaly) {
    final key = _itemKeys[anomaly.id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    if (widget.evidenceItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined, size: 64, color: AppColors.statusSuccess),
              const SizedBox(height: 16),
              const Text(
                'No Evidence Items Recorded',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'The forensic engine found no critical anomalies or evidence markers in this video file.',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryTextColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final categories = ['ALL', 'AI CONTENT', 'MODIFICATION', 'PTS GAP', 'VISUAL DISCONT.', 'CORRUPTION', 'FREEZE / DUP', 'SCENE CUTS'];

    final filteredItems = widget.evidenceItems.where((item) {
      if (_selectedCategory == 'ALL') return true;
      if (_selectedCategory == 'AI CONTENT') return item.isAiCandidate;
      if (_selectedCategory == 'MODIFICATION') return item.isModification;
      if (_selectedCategory == 'PTS GAP') return item.isPtsGap;
      if (_selectedCategory == 'VISUAL DISCONT.') return item.isVisualDiscontinuity;
      if (_selectedCategory == 'CORRUPTION') return item.isCorruptedFrame || item.isVisualAnomaly;
      if (_selectedCategory == 'FREEZE / DUP') return item.type.contains('FREEZE') || item.type.contains('DUPLICATE');
      if (_selectedCategory == 'SCENE CUTS') return item.type.contains('SCENE');
      return true;
    }).toList();

    // Generate keys for scroll mapping
    for (final item in filteredItems) {
      _itemKeys.putIfAbsent(item.id, () => GlobalKey());
    }

    // Determine max duration for timeline map
    double maxTime = widget.videoDuration;
    if (maxTime <= 0) {
      for (final a in widget.evidenceItems) {
        if (a.timestampEnd > maxTime) maxTime = a.timestampEnd;
      }
    }
    if (maxTime <= 0) maxTime = 10.0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FORENSIC TIMELINE MAP
          ForensicCard(
            borderColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            child: ForensicTimelineWidget(
              duration: maxTime,
              anomalies: widget.evidenceItems,
              onAnomalySelected: (anomaly) {
                // Switch category if needed
                setState(() {
                  _selectedCategory = 'ALL';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToAnomaly(anomaly);
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // 2. CATEGORY FILTER CHIPS BAR
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569)),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 3. EXPANDABLE EVIDENCE CARDS LIST
          if (filteredItems.isEmpty)
            ForensicCard(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No evidence items matching selected category filter.',
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ...filteredItems.map((item) {
              final Color catColor = _getCategoryColor(item.type);
              final key = _itemKeys[item.id];

              return ForensicCard(
                key: key,
                margin: const EdgeInsets.only(bottom: 12),
                borderColor: catColor.withValues(alpha: 0.3),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(_getCategoryIcon(item.type), color: catColor, size: 20),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.anomalyType,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ConfidenceBadge(confidence: item.confidence, compact: true),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Detector: ${item.detector}  •  Frames: ${item.frameStart}–${item.frameEnd}',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Evidence Text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Evidence: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Expanded(
                          child: Text(
                            item.evidence.isNotEmpty ? item.evidence : 'Automated detector candidate recorded.',
                            style: const TextStyle(fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Key-Value Metadata Grid
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Frame Range', '${item.frameStart} – ${item.frameEnd} (${(item.frameEnd - item.frameStart + 1)} frames)', isDark, secondaryTextColor),
                          _buildDetailRow('Timestamp Range', '${item.timestampStart.toStringAsFixed(2)}s – ${item.timestampEnd.toStringAsFixed(2)}s', isDark, secondaryTextColor),
                          _buildDetailRow('Duration', '${item.duration.toStringAsFixed(2)}s', isDark, secondaryTextColor),
                          _buildDetailRow('Anomaly Score', item.score.toStringAsFixed(4), isDark, secondaryTextColor),
                          _buildDetailRow('Confidence Level', item.confidence.toUpperCase(), isDark, secondaryTextColor),

                          // PTS Gap vs Visual Discontinuity Distinction
                          if (item.isPtsGap)
                            _buildDetailRow('PTS Timestamp Gap', 'PTS gap detected (${item.duration.toStringAsFixed(3)}s interval)', isDark, secondaryTextColor)
                          else if (item.isVisualDiscontinuity)
                            _buildDetailRow('Missing Frames (PTS)', '0 (No PTS gap detected — visual continuity candidate only)', isDark, secondaryTextColor),

                          if (item.regions.isNotEmpty)
                            _buildDetailRow('Region Coordinates', item.regions.join(', '), isDark, secondaryTextColor),
                        ],
                      ),
                    ),

                    // Signals Chips
                    if (item.signals.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.signals.entries.map((entry) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.analytics, size: 12),
                            label: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Frame Preview Widget
                    const FramePreviewWidget(),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Open Detailed Evidence View', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnomalyDetailScreen(anomaly: item),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: secondaryColor)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('AI_CONTENT')) return Colors.indigo;
    if (t.contains('MODIFICATION')) return Colors.purple;
    if (t.contains('VISUAL_DISCONTINUITY')) return Colors.deepOrange;
    if (t.contains('VISUAL_ANOMALY')) return AppColors.statusError;
    if (t.contains('PTS_GAP')) return Colors.orange;
    return AppColors.primaryAccent;
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('AI_CONTENT')) return Icons.psychology;
    if (t.contains('MODIFICATION')) return Icons.edit_note;
    if (t.contains('VISUAL_DISCONTINUITY')) return Icons.broken_image;
    if (t.contains('VISUAL_ANOMALY')) return Icons.auto_awesome_motion;
    if (t.contains('PTS_GAP')) return Icons.find_replace;
    return Icons.warning_amber;
  }
}
