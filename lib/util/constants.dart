import 'package:flutter/foundation.dart';

const bool useLocalServer = false && kDebugMode;

const HOST = useLocalServer ? "192.168.172.224" : "fourinarow.ffactory.me";
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

const int PROTOCOL_VERSION = 4;

const int STARTUP_DELAY_MS = 500;

const int QUICKCHAT_EMOJI_COUNT = 4;

const String LINKEDIN_PROFILE = "https://www.linkedin.com/in/filippo-orru/";
const String PRIVACY_POLICY = "https://fourinarow.ffactory.me/privacy.html";

const List<String> ALLOWED_QUICKCHAT_EMOJIS = [
  "😀",
  "😁",
  "😂",
  "😃",
  "😄",
  "😅",
  "😆",
  "😉",
  "😊",
  "😋",
  "😎",
  "😍",
  "☺️",
  "🙂",
  "🤗",
  "🤔",
  "😐",
  "😑",
  "😶",
  "🙄",
  "😏",
  "😣",
  "😥",
  "😮",
  "🤐",
  "😯",
  "😪",
  "😫",
  "😴",
  "😌",
  "🤓",
  "😜",
  "😝",
  "😒",
  "😓",
  "😔",
  "😕",
  "🙃",
  "😲",
  "☹️",
  "🙁",
  "😖",
  "😞",
  "😟",
  "😤",
  "😢",
  "😭",
  "😦",
  "😧",
  "😨",
  "😩",
  "😬",
  "😰",
  "😱",
  "😳",
  "😵",
  "😡",
  "😠",
  "😇",
  "😈",
  "😺",
  "😸",
  "😹",
  "😻",
  "😼",
  "😽",
  "🙀",
  "😿",
  "😾",
  "🙈",
  "🙉",
  "🙊",
  "💪",
  "✌️",
  "👌",
  "👍",
  "👎",
  "👋",
  "👏",
  "🙌",
  "💭",
  "🐶",
  "🐺",
  "🦊",
  "🐱",
  "🐈",
  "🌚",
  "🌝",
  "🌞",
  "🏅",
  "🎉",
  "🎇",
  "✨",
  "🎆",
  "🏆"
];

const bool SKIP_SPLASH_ANIM_ON_DEBUG = kDebugMode && false;
