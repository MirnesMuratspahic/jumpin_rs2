import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/ad.dart';

/// Builds and exports the admin PDF reports.
/// Reports are written to the user's Downloads folder and opened in the system
/// PDF viewer (Preview), from where they can be viewed and printed. This avoids
/// the sandboxed print-service issues on macOS and keeps the app responsive.
class ReportService {
  static final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _date = DateFormat('dd.MM.yyyy');
  static final DateFormat _stamp = DateFormat('yyyyMMdd-HHmmss');

  static const PdfColor _primary = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFFE3F2FD);

  /// Saves the report to ~/Downloads (falling back to the temp dir) and opens
  /// it in the default PDF viewer. Returns the saved file path.
  static Future<String> exportPdf(Uint8List bytes, String name) async {
    final home = Platform.environment['HOME'];
    Directory dir = Directory.systemTemp;
    if (home != null) {
      final downloads = Directory('$home/Downloads');
      if (await downloads.exists()) dir = downloads;
    }

    final path = '${dir.path}/$name-${_stamp.format(DateTime.now())}.pdf';
    await File(path).writeAsBytes(bytes, flush: true);

    // Open in the default viewer (non-blocking; app stays usable).
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
    return path;
  }

  /// Saves a CSV file to ~/Downloads (falling back to temp) and opens it in the
  /// default app (Excel/Numbers). Returns the saved path. CSV is used for further
  /// business analysis/processing, separate from the PDF reports.
  static Future<String> exportCsv(String content, String name) async {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];
    Directory dir = Directory.systemTemp;
    if (home != null) {
      final downloads = Directory('$home/Downloads');
      if (await downloads.exists()) dir = downloads;
    }

    final path = '${dir.path}/$name-${_stamp.format(DateTime.now())}.csv';
    // Prepend a BOM so Excel opens UTF-8 content correctly.
    await File(path).writeAsString('﻿$content', flush: true);

    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
    return path;
  }

  static String _csvField(Object? v) {
    final s = (v ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _csvRow(List<Object?> cells) =>
      cells.map(_csvField).join(',');

  // CSV of the dashboard statistics (users, ads, requests by status, VIP, …).
  static String buildStatisticsCsv(Map<String, dynamic> stats) {
    int n(String key) =>
        (stats[key] ?? 0) is num ? (stats[key] ?? 0).toInt() : 0;

    final rows = <String>[_csvRow(['Metric', 'Value'])];
    rows.add(_csvRow(['Total users', n('totalUsers')]));
    rows.add(_csvRow(['Active users', n('activeUsers')]));
    rows.add(_csvRow(['Blocked users', n('blockedUsers')]));
    rows.add(_csvRow(['VIP users', n('vipUsers')]));
    rows.add(_csvRow(['New users this month', n('newUsersThisMonth')]));
    rows.add(_csvRow(['Total ads', n('totalAds')]));
    rows.add(_csvRow(['Total requests', n('totalRequests')]));
    rows.add(_csvRow(['Total reviews', n('totalReviews')]));
    rows.add(_csvRow(['Support messages', n('totalSupportMessages')]));
    rows.add(_csvRow(['Open support messages', n('openSupportMessages')]));

    final adsByType = (stats['adsByType'] as Map?)?.cast<String, dynamic>() ?? {};
    adsByType.forEach((k, v) => rows.add(_csvRow(['Ads - $k', v])));

    final reqByStatus =
        (stats['requestsByStatus'] as Map?)?.cast<String, dynamic>() ?? {};
    reqByStatus.forEach((k, v) => rows.add(_csvRow(['Requests - $k', v])));

    final avg = stats['averageRating'];
    rows.add(_csvRow(
        ['Average rating', avg is num ? avg.toStringAsFixed(2) : '0.00']));

    return rows.join('\n');
  }

  // CSV of an ads listing (title, type, price, status, owner, created date).
  static String buildAdsCsv(List<Ad> ads) {
    final rows = <String>[
      _csvRow(['Title', 'Type', 'Owner', 'Price', 'Status', 'Created'])
    ];
    for (final a in ads) {
      rows.add(_csvRow([
        a.title ?? '',
        a.type ?? '',
        a.ownerFullName?.isNotEmpty == true
            ? a.ownerFullName!
            : (a.ownerUsername ?? ''),
        a.price != null ? a.price!.toStringAsFixed(2) : '',
        a.status ?? '',
        a.createdAt != null ? _date.format(a.createdAt!) : '',
      ]));
    }
    return rows.join('\n');
  }

  // ---------------- Report 1: Statistics overview ----------------

  static Future<Uint8List> buildStatisticsReport(Map<String, dynamic> stats) async {
    final doc = pw.Document();
    final generatedAt = _dateTime.format(DateTime.now());

    int n(String key) => (stats[key] ?? 0) is num ? (stats[key] ?? 0).toInt() : 0;
    String pct(String key) {
      final v = stats[key];
      if (v is num) return '${v.toStringAsFixed(1)}%';
      return '0.0%';
    }

    final adsByType = (stats['adsByType'] as Map?)?.cast<String, dynamic>() ?? {};
    final reqByStatus =
        (stats['requestsByStatus'] as Map?)?.cast<String, dynamic>() ?? {};

    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        header: (ctx) => _header(ctx, 'Statistics Report', generatedAt),
        footer: _footer,
        build: (ctx) => [
          _sectionTitle('Overview'),
          _kvTable({
            'Total users': '${n('totalUsers')}',
            'Active users': '${n('activeUsers')}',
            'Blocked users': '${n('blockedUsers')}',
            'VIP users': '${n('vipUsers')}',
            'New users this month': '${n('newUsersThisMonth')}',
            'Total ads': '${n('totalAds')}',
            'Total requests': '${n('totalRequests')}',
            'Total reviews': '${n('totalReviews')}',
            'Support messages': '${n('totalSupportMessages')}',
            'Open support messages': '${n('openSupportMessages')}',
          }),
          pw.SizedBox(height: 18),
          _sectionTitle('Ads by type'),
          _countTable('Type', adsByType),
          pw.SizedBox(height: 18),
          _sectionTitle('Requests by status'),
          _countTable('Status', reqByStatus),
          pw.SizedBox(height: 18),
          _sectionTitle('Platform health'),
          _kvTable({
            'Average rating': (stats['averageRating'] is num)
                ? (stats['averageRating'] as num).toStringAsFixed(2)
                : '0.00',
            'Support response rate': pct('supportResponseRate'),
            'Ad completion rate': pct('adCompletionRate'),
            'Request accept rate': pct('requestAcceptRate'),
          }),
        ],
      ),
    );

    return doc.save();
  }

  // ---------------- Report 2: Ads listing ----------------

  static Future<Uint8List> buildAdsReport(List<Ad> ads, {String? filterLabel}) async {
    final doc = pw.Document();
    final generatedAt = _dateTime.format(DateTime.now());

    final headers = ['#', 'Title', 'Type', 'Owner', 'Price', 'Status', 'Created'];
    final rows = <List<String>>[];
    for (var i = 0; i < ads.length; i++) {
      final a = ads[i];
      rows.add([
        '${i + 1}',
        a.title ?? '-',
        a.type ?? '-',
        a.ownerFullName?.isNotEmpty == true
            ? a.ownerFullName!
            : (a.ownerUsername ?? '-'),
        a.price != null ? '${a.price!.toStringAsFixed(2)} KM' : '-',
        a.status ?? '-',
        a.createdAt != null ? _date.format(a.createdAt!) : '-',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        header: (ctx) => _header(ctx, 'Ads Report', generatedAt),
        footer: _footer,
        build: (ctx) => [
          pw.Text('Total ads: ${ads.length}',
              style: const pw.TextStyle(fontSize: 11)),
          if (filterLabel != null && filterLabel.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('Filter: $filterLabel',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: _headerBg),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ---------------- Shared building blocks ----------------

  static pw.PageTheme _pageTheme() => pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
      );

  static pw.Widget _header(pw.Context ctx, String title, String generatedAt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('JumpIn',
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _primary)),
              pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.Text('Generated: $generatedAt',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: _primary)),
      );

  static pw.Widget _kvTable(Map<String, String> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: data.entries
          .map((e) => pw.TableRow(children: [
                _cell(e.key, bold: false),
                _cell(e.value, bold: true),
              ]))
          .toList(),
    );
  }

  static pw.Widget _countTable(String label, Map<String, dynamic> data) {
    if (data.isEmpty) {
      return pw.Text('No data.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [_cell(label, bold: true), _cell('Count', bold: true)],
        ),
        ...data.entries.map((e) => pw.TableRow(children: [
              _cell(e.key),
              _cell('${e.value}'),
            ])),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
}
