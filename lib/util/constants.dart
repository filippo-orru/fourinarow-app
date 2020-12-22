import 'package:flutter/foundation.dart';

const bool useLocalServer = true;

const HOST =
    kDebugMode && useLocalServer ? "192.168.178.42:40146" : "fourinarow.ml";

const URL = kDebugMode && useLocalServer ? "http://$HOST" : "https://$HOST";

const WS_URL =
    kDebugMode && useLocalServer ? "ws://$HOST/game/" : "wss://$HOST/v2/game/";

const String alphabet = "abcdefghijklmnopqrstuvwxyz";

const int QUEUE_CHECK_INTERVAL_MS = 500;

const int QUEUE_RESEND_TIMEOUT_MS = 1000;

const int PROTOCOL_VERSION = 2;
