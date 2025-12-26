import 'package:logger/logger.dart' as logger;

late logger.Logger _logger;
late logger.Logger _logger5;
late logger.Logger _logger10;

logger.Logger get log => _logger;
logger.Logger get log5 => _logger5;
logger.Logger get log10 => _logger10;

class Logger {
  Logger._();

  static bool _isConfigured = false;
  static bool _isInitializing = false;

  static Future<void> configure({
    logger.Level level = logger.Level.debug,
    bool colors = true,
  }) async {
    if (_isConfigured || _isInitializing) {
      print('Logger configuration skipped - already configured or initializing');
      return;
    }

    _isInitializing = true;

    try {
      // Use microtask to ensure we're in a stable async state
      await Future.microtask(() {});

      // Initialize loggers
      _logger = logger.Logger(
        level: level,
        printer: logger.PrettyPrinter(
          methodCount: 0,
          colors: colors,
          printTime: true,
        ),
      );

      _logger5 = logger.Logger(
        level: level,
        printer: logger.PrettyPrinter(
          methodCount: 5,
          colors: colors,
          printTime: true,
        ),
      );

      _logger10 = logger.Logger(
        level: level,
        printer: logger.PrettyPrinter(
          methodCount: 10,
          colors: colors,
          printTime: true,
        ),
      );

      _isConfigured = true;
      
      // Safe to log now
      _logger.i('Logger configured successfully');
    } catch (e, stackTrace) {
      print('Error during logger configuration: $e');
      // Re-throw to see the actual error
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
}