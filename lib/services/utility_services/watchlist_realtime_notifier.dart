import 'package:flutter/foundation.dart';

final ValueNotifier<Map<int, String>> globalOptimisticStatus =
    ValueNotifier<Map<int, String>>({});

void setOptimisticMediaStatus(int mediaId, String status) {
  setOptimisticMediaStatuses({mediaId: status});
}

void setOptimisticMediaStatuses(Map<int, String> statuses) {
  if (statuses.isEmpty) return;

  final nextStatuses = Map<int, String>.from(globalOptimisticStatus.value);
  nextStatuses.addAll(statuses);
  globalOptimisticStatus.value = nextStatuses;
}

void clearOptimisticMediaStatus(int mediaId) {
  clearOptimisticMediaStatuses({mediaId});
}

void clearOptimisticMediaStatuses(Iterable<int> mediaIds) {
  final ids = mediaIds.toSet();
  if (ids.isEmpty) return;

  final nextStatuses = Map<int, String>.from(globalOptimisticStatus.value);
  nextStatuses.removeWhere((mediaId, _) => ids.contains(mediaId));
  globalOptimisticStatus.value = nextStatuses;
}
