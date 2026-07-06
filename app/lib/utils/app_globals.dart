import 'package:flutter/material.dart';

/// App-wide navigator key. Lets background services (e.g. the incoming-alert
/// listener) push the full-screen emergency alarm no matter which screen or
/// tab is currently on top.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
