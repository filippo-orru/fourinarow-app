import 'package:flutter/foundation.dart';

const bool useLocalServer = false && kDebugMode;

const HOST = useLocalServer ? "192.168.0.213" : "fourinarow.ml";
const PORT = useLocalServer ? 40146 : 80;
const HOST_PORT = useLocalServer ? "$HOST:$PORT" : HOST;

const HTTP_PREFIX = "http" + (useLocalServer ? "" : "s");
const WS_PREFIX = "ws" + (useLocalServer ? "" : "s");
const HTTP_URL = HTTP_PREFIX + "://$HOST_PORT";

const WS_PATH = "$HOST_PORT/game/";

// const WS_URL = (useLocalServer ? "http" : "https") + "://$WS_PATH";

const String alphabet = "abcdefghijklmnopqrstuvwxyz";

const int QUEUE_CHECK_INTERVAL_MS = 250;

const int QUEUE_RESEND_TIMEOUT_MS = 700;

const int CHECK_CONN_INTERVAL_MS = 1000;

const int PROTOCOL_VERSION = 2;

const int STARTUP_DELAY_MS = 600;
