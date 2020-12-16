import 'package:flutter/foundation.dart';

const URL = "https://fourinarow.ml";

const bool useLocalServer = true;

const WS_URL = kDebugMode && useLocalServer
    ? "ws://192.168.178.42:40146/game/"
    : "wss://fourinarow.ml/v2/game/";

const String alphabet = "abcdefghijklmnopqrstuvwxyz";

const int QUEUE_CHECK_INTERVAL_MS = 500;

const int QUEUE_RESEND_TIMEOUT_MS = 1000;

const int PROTOCOL_VERSION = 2;
