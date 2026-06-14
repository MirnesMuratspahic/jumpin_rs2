import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'api_exception.dart';

/// Shows a user-facing error for a failed API call. Distinguishes the error
/// kinds the way the review checklist requires:
///  - 401 -> log the user out and send them back to the login screen
///  - 403 -> "no permission" message
///  - 5xx -> "server error" message
///  - everything else -> the backend message or a generic fallback
///
/// Call this from a screen's catch block. It is a no-op if [context] is no
/// longer mounted.
void showApiError(BuildContext context, Object error) {
  if (!context.mounted) return;

  final message = error is ApiException
      ? error.message
      : 'Something went wrong. Please try again.';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );

  if (error is ApiException && error.isUnauthorized) {
    _forceReLogin(context);
  }
}

void _forceReLogin(BuildContext context) {
  // Clear the stored session, then route to login removing the back stack.
  Provider.of<AuthProvider>(context, listen: false).logout();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
