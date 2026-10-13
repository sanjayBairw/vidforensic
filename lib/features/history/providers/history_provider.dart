import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_provider.dart';
import '../models/history_item.dart';

const String _historyStorageKey = 'vidforensic_history_v1';

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  final ApiClient _apiClient;
  Timer? _pollingTimer;

  HistoryNotifier(this._apiClient) : super([]) {
    loadHistory();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> loadHistory() async {
    await _loadFromLocalCache();
    await refreshHistory();
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_historyStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        state = list.map((item) => HistoryItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> refreshHistory() async {
    try {
      final res = await _apiClient.getJobsHistory(page: 1, pageSize: 50);
      final itemsData = res['items'] as List<dynamic>? ?? [];
      final List<HistoryItem> items = itemsData
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
      state = items;
      await _saveToStorage(items);
      _checkPollingNeed();
    } catch (e) {
      // Retain local cached state if server unreachable
    }
  }

  void _checkPollingNeed() {
    _pollingTimer?.cancel();
    final hasProcessing = state.any((item) {
      final s = item.status.toUpperCase();
      return s == 'PROCESSING' || s == 'QUEUED' || s == 'UPLOADED';
    });

    if (hasProcessing) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        refreshHistory();
      });
    }
  }

  Future<void> addItem(HistoryItem item) async {
    final filtered = state.where((e) => e.jobId != item.jobId).toList();
    final updated = [item, ...filtered];
    state = updated;
    await _saveToStorage(updated);
    _checkPollingNeed();
  }

  Future<bool> deleteJob(String jobId) async {
    try {
      await _apiClient.deleteJob(jobId);
    } catch (_) {
      // Best effort delete if server error
    }
    final updated = state.where((item) => item.jobId != jobId).toList();
    state = updated;
    await _saveToStorage(updated);
    return true;
  }

  Future<void> clearHistory() async {
    for (final item in state) {
      try {
        await _apiClient.deleteJob(item.jobId);
      } catch (_) {}
    }
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyStorageKey);
  }

  Future<void> _saveToStorage(List<HistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_historyStorageKey, jsonStr);
    } catch (_) {}
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HistoryNotifier(apiClient);
});
