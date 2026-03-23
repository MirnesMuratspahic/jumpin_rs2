import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildResultView(Widget child) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromRGBO(224, 224, 224, 1),
          width: 1,
        ),
      ),
      child: child,
    ),
  );
}

Future<dynamic> buildErrorAlert(
  BuildContext context,
  String title,
  String text,
  Exception exception,
) async {
  String errorMessage = text;

  if (text.startsWith('Exception: ')) {
    errorMessage = text.substring('Exception: '.length);
  }

  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

Future<dynamic> buildSuccessAlert(
  BuildContext context,
  String title,
  String text,
) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

String formatDateString(String? dateString) {
  if (dateString == null) return "";
  try {
    DateTime date = DateTime.parse(dateString);
    return DateFormat('dd.MM.yyyy').format(date);
  } catch (e) {
    return dateString;
  }
}

String formatDateTimeString(String? dateTimeString) {
  if (dateTimeString == null) return "";
  try {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  } catch (e) {
    return dateTimeString;
  }
}

String formatDate(DateTime? date) {
  if (date == null) return "";
  return DateFormat('dd.MM.yyyy').format(date);
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return "";
  return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
}

String formatCurrency(dynamic amount) {
  if (amount == null) return "0.00 KM";
  double value = 0.0;
  if (amount is String) {
    value = double.tryParse(amount) ?? 0.0;
  } else if (amount is num) {
    value = amount.toDouble();
  }
  return "${value.toStringAsFixed(2)} KM";
}
