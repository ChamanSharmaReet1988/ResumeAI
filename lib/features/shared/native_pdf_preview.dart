import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

class NativePdfPreview extends StatefulWidget {
  const NativePdfPreview({
    super.key,
    required this.bytesFuture,
    required this.documentKey,
    required this.viewerBackground,
    this.pageMargin = 10,
    this.horizontalPadding = 5,
  });

  final Future<Uint8List> bytesFuture;

  /// Stable id for [PdfViewer.data] `sourceName` (must change when the PDF bytes change).
  final String documentKey;
  final Color viewerBackground;

  /// Space around each PDF page inside the viewer.
  final double pageMargin;

  /// Extra horizontal inset around the viewer.
  final double horizontalPadding;

  @override
  State<NativePdfPreview> createState() => _NativePdfPreviewState();
}

class _NativePdfPreviewState extends State<NativePdfPreview> {
  int _currentPage = 1;
  int _totalPages = 1;
  late Future<Uint8List> _cachedBytesFuture;

  late PdfViewerParams _viewerParams;

  @override
  void initState() {
    super.initState();
    _cachedBytesFuture = widget.bytesFuture;
  }

  @override
  void didUpdateWidget(covariant NativePdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentKey != widget.documentKey) {
      _cachedBytesFuture = widget.bytesFuture;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewerParams = PdfViewerParams(
      margin: widget.pageMargin,
      backgroundColor: widget.viewerBackground,
      pageDropShadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
      scrollPhysics: PdfViewerParams.getScrollPhysics(context),
      // By default each page is drawn from a 200 dpi image scaled down to the
      // screen with low-quality filtering, which blurs thin text. Keeping the
      // one-pass image below the on-screen scale makes the viewer overlay a
      // render at the exact device resolution, so text stays crisp.
      getPageRenderingScale: (context, page, controller, estimatedScale) =>
          math.min(estimatedScale, 1.0),
      onPageChanged: _onPdfPageChanged,
      onViewerReady: _onPdfViewerReady,
    );
  }

  void _onPdfPageChanged(int? pageNumber) {
    if (!mounted) {
      return;
    }
    setState(() => _currentPage = pageNumber ?? 1);
  }

  void _onPdfViewerReady(PdfDocument document, PdfViewerController controller) {
    if (!mounted) {
      return;
    }
    setState(() {
      _totalPages = document.pages.length;
      _currentPage = controller.pageNumber ?? 1;
    });
  }

  PdfDocumentRef? _documentRef;
  Uint8List? _documentBytes;

  /// Returns the same [PdfDocumentRef] for the same bytes across rebuilds.
  ///
  /// [PdfViewer] only starts loading after pdfrx finishes initializing, which
  /// is slow on the first preview after launch. If the parent rebuilds during
  /// that wait, a fresh ref (same key) makes the viewer's pending load bail out
  /// on its identity check, and the page stays blank until the next open.
  PdfDocumentRef _documentRefFor(Uint8List bytes) {
    final current = _documentRef;
    if (current != null &&
        identical(_documentBytes, bytes) &&
        current.key.sourceName == widget.documentKey) {
      return current;
    }
    _documentBytes = bytes;
    return _documentRef = PdfDocumentRefData(
      bytes,
      sourceName: widget.documentKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _cachedBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(context.l10n.unableToLoadPdfPreview),
          );
        }

        final theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: PdfViewer(
                  _documentRefFor(snapshot.data!),
                  params: _viewerParams,
                ),
              ),
              Positioned(
                top: 14,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
