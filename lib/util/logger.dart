import 'package:logger/logger.dart' as lib;

import 'logger_printer.dart';

class Logger {
  Logger._();

  static final lib.Logger _logger = lib.Logger(
    filter: lib.DevelopmentFilter(),
    printer: CustomPrinter(),
  );

  /// Log a message at level [lib.Level.verbose].
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.verbose, message, error, stackTrace);
  }

  /// Log a message at level [lib.Level.debug].
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.debug, message, error, stackTrace);
  }

  /// Log a message at level [lib.Level.info].
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.info, message, error, stackTrace);
  }

  /// Log a message at level [lib.Level.warning].
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.warning, message, error, stackTrace);
  }

  /// Log a message at level [lib.Level.error].
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.error, message, error, stackTrace);
  }

  /// Log a message at level [lib.Level.wtf].
  static void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.log(lib.Level.wtf, message, error, stackTrace);
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
