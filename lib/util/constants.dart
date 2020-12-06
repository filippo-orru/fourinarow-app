import 'package:flutter/foundation.dart';

const URL = "https://fourinarow.ml";

const bool useLocalServer = false;

const WS_URL = kDebugMode && useLocalServer
    ? "ws://192.168.178.42:40146/game/"
    : "wss://fourinarow.ml/game/";

const String alphabet = "abcdefghijklmnopqrstuvwxyz";
