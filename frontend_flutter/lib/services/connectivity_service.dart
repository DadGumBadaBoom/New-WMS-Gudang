import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

// Service sederhana untuk pantau konektivitas
class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription _sub;

  ConnectivityService() {
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      _controller.add(isOnline);
    });
  }

  Stream<bool> get statusStream => _controller.stream;

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
