import 'package:flutter/foundation.dart';

/// Debug-only logging. Nothing is emitted in release builds, so tokens, request
/// bodies and other sensitive data never reach production logs. Never pass
/// auth headers, tokens, passwords or full user objects here.
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

void logError(String message, [Object? error]) {
  if (kDebugMode) {
    debugPrint(error == null ? message : '$message: $error');
  }
}
