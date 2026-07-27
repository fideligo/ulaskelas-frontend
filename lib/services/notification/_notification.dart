// Transport, permission, badge and payload parsing. Navigation is intentionally
// absent: `NotificationService.onPayloadTapped` is the seam the router hooks
// into, keeping this layer testable without a NavigatorState.

import 'dart:async';
import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulaskelas/core/constants/_constants.dart';
import 'package:ulaskelas/services/_services.dart';

part 'badge_service.dart';
part 'fcm_client.dart';
part 'local_notification_client.dart';
part 'notification_channel.dart';
part 'notification_permission.dart';
part 'notification_service.dart';
part 'payload/notification_payload.dart';
