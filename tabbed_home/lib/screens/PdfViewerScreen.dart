import 'package:flutter/foundation.dart'; // <-- Add this
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;

class PdfViewerScreen extends StatefulWidget {
  final String assetPath;
  final String screenTitle;

  const PdfViewerScreen({
    super.key,
    required this.assetPath,
    required this.screenTitle,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadPdf();
    } else {
      _isLoading = false;
    }
  }

  Future<Uint8List> _loadPdfBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to load PDF: $e');
    }
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await _loadPdfBytes(widget.assetPath);
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // optional localization

    return Scaffold(
      appBar: AppBar(title: Text(widget.screenTitle)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : kIsWeb
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n?.pdfNotSupportedOnWeb ??
                          'PDF viewing is not supported on this device. Please download the file.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _pdfBytes != null
                  ? PDFView(
                      pdfData: _pdfBytes!,
                      enableSwipe: true,
                      pageSnap: true,
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF Error: $error')),
                        );
                      },
                    )
                  : Center(child: Text('Failed to load PDF')),
    );
  }
}
