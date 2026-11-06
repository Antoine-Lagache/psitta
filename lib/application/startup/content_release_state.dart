import 'dart:async';

import 'package:flutter/foundation.dart';

enum ContentReleaseStatus { loading, ready, failed }

/// Publishes the lifecycle of content installed after the initial database.
class ContentReleaseState extends ChangeNotifier {
  ContentReleaseStatus _status = ContentReleaseStatus.loading;
  ContentReleaseStatus get status => _status;
  bool get isLoading => _status == ContentReleaseStatus.loading;
  bool get hasFailed => _status == ContentReleaseStatus.failed;
  late final Future<void> completed;

  ContentReleaseState(Future<bool> installation) {
    completed = _observe(installation);
    unawaited(completed);
  }

  Future<void> _observe(Future<bool> installation) async {
    try {
      await installation;
      _status = ContentReleaseStatus.ready;
    } on Object {
      _status = ContentReleaseStatus.failed;
    }
    notifyListeners();
  }
}
