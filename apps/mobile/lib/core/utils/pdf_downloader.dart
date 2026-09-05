import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../theme/app_colors.dart';

class PdfDownloader {
  static Future<void> downloadAndOpenPdf({
    required BuildContext context,
    required String url,
    required String certificateNumber,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show initial downloading notification
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text('Downloading $certificateNumber.pdf...'),
          ],
        ),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode >= 400) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedCertNum = certificateNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '${dir.path}/$sanitizedCertNum.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      final sizeKb = (bytes.length / 1024).toStringAsFixed(1);

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.verifiedGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saved $sanitizedCertNum.pdf ($sizeKb KB)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: AppColors.cyanAccent,
            onPressed: () {
              OpenFilex.open(filePath);
            },
          ),
          duration: const Duration(seconds: 7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Automatically open the downloaded PDF
      try {
        await OpenFilex.open(filePath);
      } catch (openErr) {
        debugPrint('OpenFilex note: $openErr');
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
