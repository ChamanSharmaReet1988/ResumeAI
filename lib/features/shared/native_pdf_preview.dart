import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class NativePdfPreview extends StatefulWidget {
  const NativePdfPreview({
    super.key,
    required this.bytesFuture,
    required this.documentKey,
    required this.viewerBackground,
  });

  final Future<Uint8List> bytesFuture;

  /// Stable id when PDF bytes change (new rasterization).
  final String documentKey;
  final Color viewerBackground;

  @override
  State<NativePdfPreview> createState() => _NativePdfPreviewState();
}

class _NativePdfPreviewState extends State<NativePdfPreview> {
  late Future<Uint8List> _cachedBytesFuture;

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
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _cachedBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Unable to load PDF preview right now.'),
          );
        }

        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _PrintingPdfScrollView(
            key: ValueKey(widget.documentKey),
            bytes: snapshot.data!,
            theme: theme,
            backgroundColor: widget.viewerBackground,
          ),
        );
      },
    );
  }
}

class _PdfPreviewScrollData extends InheritedNotifier<ValueNotifier<_PdfScrollModel>> {
  const _PdfPreviewScrollData({
    required super.notifier,
    required super.child,
  });

  static ValueNotifier<_PdfScrollModel>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PdfPreviewScrollData>()
        ?.notifier;
  }
}

class _PdfScrollModel {
  const _PdfScrollModel({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;
}

class _PrintingPdfScrollView extends StatefulWidget {
  const _PrintingPdfScrollView({
    super.key,
    required this.bytes,
    required this.theme,
    required this.backgroundColor,
  });

  final Uint8List bytes;
  final ThemeData theme;
  final Color backgroundColor;

  @override
  State<_PrintingPdfScrollView> createState() => _PrintingPdfScrollViewState();
}

class _PrintingPdfScrollViewState extends State<_PrintingPdfScrollView> {
  static const double _horizontalMargin = 10;
  static const double _pageGap = 10;
  static const double _listTopPadding = 8;
  static const double _listBottomPadding = 24;
  static const double _rasterDpi = 72 * 2;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<_PdfScrollModel> _scrollModel =
      ValueNotifier(const _PdfScrollModel(currentPage: 1, totalPages: 1));

  late Future<List<PdfRaster>> _pagesFuture;
  List<PdfRaster> _pages = [];
  List<double> _pageTops = [];
  List<double> _pageBottoms = [];

  @override
  void initState() {
    super.initState();
    _pagesFuture = _rasterize();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _PrintingPdfScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      _pagesFuture = _rasterize();
      _pages = [];
      _pageTops = [];
      _pageBottoms = [];
      _scrollModel.value = const _PdfScrollModel(currentPage: 1, totalPages: 1);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollModel.dispose();
    super.dispose();
  }

  Future<List<PdfRaster>> _rasterize() async {
    final pages = <PdfRaster>[];
    await for (final page in Printing.raster(
      widget.bytes,
      dpi: _rasterDpi,
    )) {
      pages.add(page);
    }
    return pages;
  }

  void _layoutMetricsForWidth(double maxWidth) {
    if (_pages.isEmpty) {
      return;
    }
    final tops = <double>[];
    final bottoms = <double>[];
    var y = _listTopPadding;
    for (final r in _pages) {
      tops.add(y);
      final scale = maxWidth / r.width;
      y += r.height * scale;
      bottoms.add(y);
      y += _pageGap;
    }
    _pageTops = tops;
    _pageBottoms = bottoms;
  }

  void _onScroll() {
    if (_pages.isEmpty || _pageBottoms.isEmpty) {
      return;
    }
    final pixels = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final viewport = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 0.0;
    final anchor = pixels + viewport * 0.25;

    var page = 1;
    for (var i = 0; i < _pages.length; i++) {
      final top = _pageTops[i];
      final bottom = _pageBottoms[i];
      if (anchor >= top && anchor < bottom) {
        page = i + 1;
        break;
      }
      if (anchor >= bottom && i == _pages.length - 1) {
        page = _pages.length;
      }
    }

    final next = _PdfScrollModel(currentPage: page, totalPages: _pages.length);
    if (next.currentPage != _scrollModel.value.currentPage ||
        next.totalPages != _scrollModel.value.totalPages) {
      _scrollModel.value = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PdfRaster>>(
      future: _pagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(
            child: Text('Unable to render PDF preview right now.'),
          );
        }

        final pages = snapshot.data!;
        if (pages.isEmpty) {
          return const Center(child: Text('Empty PDF.'));
        }

        if (_pages != pages) {
          _pages = pages;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _onScroll();
            }
          });
        }

        return _PdfPreviewScrollData(
          notifier: _scrollModel,
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth - _horizontalMargin * 2;
                  _layoutMetricsForWidth(maxW);

                  return ColoredBox(
                    color: widget.backgroundColor,
                    child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      _horizontalMargin,
                      _listTopPadding,
                      _horizontalMargin,
                      _listBottomPadding,
                    ),
                    itemCount: pages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: _pageGap),
                    itemBuilder: (context, index) {
                      final raster = pages[index];
                      final scale = maxW / raster.width;
                      final h = raster.height * scale;
                      return Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              width: maxW,
                              height: h,
                              fit: BoxFit.fill,
                              image: PdfRasterImage(raster),
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      );
                    },
                    ),
                  );
                },
              ),
              Positioned(
                top: 14,
                right: 16,
                child: _PageIndicatorChip(theme: widget.theme),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageIndicatorChip extends StatelessWidget {
  const _PageIndicatorChip({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final n = _PdfPreviewScrollData.maybeOf(context);
    if (n == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<_PdfScrollModel>(
      valueListenable: n,
      builder: (context, model, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${model.currentPage} / ${model.totalPages}',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
