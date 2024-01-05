import 'package:logger/logger.dart' as lib;

import 'logger_printer.dart';

class Logger {
  Logger._();

  static final lib.Logger _logger = lib.Logger(
    filter: lib.DevelopmentFilter(),
    printer: CustomPrinter(),
  );

  /// Log a message at level [lib.Level.trace].
  static void v(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.trace, message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [lib.Level.debug].
  static void d(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.debug, message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [lib.Level.info].
  static void i(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.info, message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [lib.Level.warning].
  static void w(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.warning, message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [lib.Level.error].
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.error, message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [lib.Level.fatal].
  static void wtf(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.fatal, message, error: error, stackTrace: stackTrace);
  }
}

class CustomFilter extends lib.LogFilter {
  @override
  bool shouldLog(lib.LogEvent event) {
    if (event.level.index >= level!.index) {
      return true;
    } else {
      return false;
    }
  }
}
