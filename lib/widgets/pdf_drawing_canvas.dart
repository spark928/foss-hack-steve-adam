import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:study_app/providers/pdf_annotation_provider.dart';
import 'package:study_app/models/academic/pdf_annotation.dart';

enum PdfTool { pen, highlighter, eraser }

class PdfDrawingCanvas extends StatefulWidget {
  final int pageNumber;
  final String pdfPath;
  final PdfPage page;
  final Rect pageRect;
  final PdfTool currentTool;
  final Color currentColor;
  final PdfViewerController controller;
  final bool isReadOnly;

  const PdfDrawingCanvas({
    super.key,
    required this.pageNumber,
    required this.pdfPath,
    required this.page,
    required this.pageRect,
    required this.currentTool,
    required this.currentColor,
    required this.controller,
    this.isReadOnly = true,
  });

  @override
  State<PdfDrawingCanvas> createState() => _PdfDrawingCanvasState();
}

class _PdfDrawingCanvasState extends State<PdfDrawingCanvas> {
  List<Offset>? _currentPath;

  Offset _screenToPdf(Offset localOffset) {
    // 1. Manual Scaling Fallback (pdfrx 2.2.24)
    // To prevent the 'shifting' bug, we map local touch points (pixels) 
    // directly to the PDF's internal coordinate system (72 DPI).
    final scale = widget.pageRect.width / widget.page.width;
    return Offset(
      localOffset.dx / scale,
      localOffset.dy / scale,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (widget.isReadOnly) return;

    if (widget.currentTool == PdfTool.eraser) {
      _eraseAt(details.localFocalPoint);
      return;
    }

    if (details.pointerCount == 1) {
      setState(() {
        _currentPath = [details.localFocalPoint];
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.isReadOnly) return;

    if (details.pointerCount > 1) {
      if (_currentPath != null) {
        setState(() => _currentPath = null);
      }
      return;
    }

    if (widget.currentTool == PdfTool.eraser) {
      _eraseAt(details.localFocalPoint);
      return;
    }

    if (_currentPath != null) {
      setState(() {
        _currentPath!.add(details.localFocalPoint);
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) async {
    if (widget.isReadOnly) return;

    if (_currentPath != null && _currentPath!.isNotEmpty) {
      final pointsToSave = List<Offset>.from(_currentPath!);
      setState(() => _currentPath = null);

      final pdfPoints = pointsToSave.map((p) => _screenToPdf(p)).toList();
      
      final type = widget.currentTool == PdfTool.highlighter 
          ? PdfAnnotationType.highlight 
          : PdfAnnotationType.pen;

      if (mounted) {
        await context.read<PdfAnnotationProvider>().addDrawingAnnotation(
          pdfPath: widget.pdfPath,
          pageNumber: widget.pageNumber,
          points: pdfPoints,
          color: type == PdfAnnotationType.highlight 
              ? widget.currentColor.withOpacity(0.3) 
              : widget.currentColor,
          type: type,
          strokeWidth: widget.currentTool == PdfTool.highlighter ? 20.0 : 2.0,
        );
      }
    }
  }

  void _eraseAt(Offset localOffset) {
    final pdfPoint = _screenToPdf(localOffset);
    context.read<PdfAnnotationProvider>().eraseAt(widget.pageNumber, pdfPoint);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.isReadOnly,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: widget.pageRect.width,
              height: widget.pageRect.height,
              child: CustomPaint(
                painter: _CanvasPainter(
                  currentPath: _currentPath,
                  tool: widget.currentTool,
                  color: widget.currentColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Offset>? currentPath;
  final PdfTool tool;
  final Color color;

  _CanvasPainter({
    this.currentPath,
    required this.tool,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPath != null && currentPath!.length > 1) {
      final paint = Paint()
        ..color = tool == PdfTool.highlighter ? color.withOpacity(0.3) : color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = tool == PdfTool.highlighter ? 20.0 : 2.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentPath![0].dx, currentPath![0].dy);
      for (int i = 1; i < currentPath!.length; i++) {
        path.lineTo(currentPath![i].dx, currentPath![i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
