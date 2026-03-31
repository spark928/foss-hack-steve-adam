import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:study_app/providers/pdf_annotation_provider.dart';
import 'package:study_app/models/academic/pdf_annotation.dart' as model;
import 'package:study_app/widgets/pdf_drawing_canvas.dart';

class PdfStudyScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfStudyScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfStudyScreen> createState() => _PdfStudyScreenState();
}

class PdfStickyNote {
  final String id;
  final int pageNumber;
  final Offset pdfPoint; // Pinned to PDF 72 DPI coordinates
  String content;
  final TextEditingController controller;

  PdfStickyNote({
    required this.id,
    required this.pageNumber,
    required this.pdfPoint,
    this.content = '',
  }) : controller = TextEditingController(text: content);
}

class _PdfStudyScreenState extends State<PdfStudyScreen> {
  final PdfViewerController _controller = PdfViewerController();
  PdfTextSelection? _selection;
  bool _isSaving = false;
  PdfTool _currentTool = PdfTool.pen;
  Color _currentColor = Colors.red;
  bool _isReadOnly = true; 
  bool _isStickyNoteMode = false;
  List<PdfStickyNote> _stickyNotes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PdfAnnotationProvider>().loadAnnotations(widget.filePath);
    });
  }

  Future<void> _handleSelectionHighlight() async {
    if (_selection == null) return;

    setState(() => _isSaving = true);
    
    try {
      final ranges = await _selection!.getSelectedTextRanges();
      
      for (final range in ranges) {
        await context.read<PdfAnnotationProvider>().addAnnotation(
          pdfPath: widget.filePath,
          pageNumber: range.pageNumber,
          rects: [range.bounds],
          color: Colors.yellow,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highlight saved!')),
        );
        setState(() {
          _selection = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isStickyNoteMode ? Icons.note_add : Icons.note_add_outlined, 
                       color: _isStickyNoteMode ? Colors.yellow : null),
            tooltip: 'Toggle Sticky Note Mode',
            onPressed: () => setState(() => _isStickyNoteMode = !_isStickyNoteMode),
          ),
          if (_selection != null && _selection!.hasSelectedText)
            IconButton(
              icon: const Icon(Icons.format_line_spacing_rounded, color: Colors.yellow),
              tooltip: 'Highlight Selection',
              onPressed: _handleSelectionHighlight,
            ),
        ],
      ),
      body: Consumer<PdfAnnotationProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              PdfViewer.file(
                widget.filePath,
                controller: _controller,
                params: PdfViewerParams(
                  backgroundColor: Colors.grey.shade900,
                  maxScale: 5.0,
                  textSelectionParams: PdfTextSelectionParams(
                    enabled: _currentTool != PdfTool.eraser,
                    onTextSelectionChange: (selection) {
                      setState(() {
                        _selection = selection;
                      });
                    },
                  ),
                  pageOverlaysBuilder: (context, pageRect, page) {
                    final items = provider.getAnnotationsForPage(page.pageNumber);
                    
                    return [
                      // Layer 1: Existing Annotations (Static)
                      ...items.map((item) {
                        final annot = item as model.PdfAnnotation;
                        if (annot.type == model.PdfAnnotationType.highlight && annot.rects != null) {
                          return Stack(
                            children: annot.rects!.map((rect) => Positioned(
                              left: rect.left,
                              top: rect.top,
                              width: rect.width,
                              height: rect.height,
                              child: Container(color: Color(annot.colorValue).withOpacity(0.3)),
                            )).toList(),
                          );
                        } else if (annot.type == model.PdfAnnotationType.pen && annot.points != null) {
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: _StaticAnnotationPainter(annotation: annot),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      
                      // Layer 2: Interactive Drawing Canvas (Top)
                      PdfDrawingCanvas(
                        pageNumber: page.pageNumber,
                        pdfPath: widget.filePath,
                        page: page,
                        pageRect: pageRect,
                        currentTool: _currentTool,
                        currentColor: _currentColor,
                        controller: _controller,
                        isReadOnly: _isReadOnly,
                      ),

                      // Layer 3: Sticky Notes (Pinned to Page Content)
                      ..._stickyNotes.where((n) => n.pageNumber == page.pageNumber).map((note) {
                        final scale = pageRect.width / page.width;
                        return Positioned(
                          left: note.pdfPoint.dx * scale,
                          top: note.pdfPoint.dy * scale,
                          child: _buildStickyNoteWidget(note),
                        );
                      }),

                      // Layer 4: Tap Listener for New Notes (Only in Sticky Mode)
                      if (_isStickyNoteMode)
                        Positioned.fill(
                          child: GestureDetector(
                            onTapDown: (details) {
                              final scale = pageRect.width / page.width;
                              setState(() {
                                _stickyNotes.add(PdfStickyNote(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  pageNumber: page.pageNumber,
                                  pdfPoint: Offset(
                                    details.localPosition.dx / scale,
                                    details.localPosition.dy / scale,
                                  ),
                                  content: '',
                                ));
                                _isStickyNoteMode = false; // Toggle off after placement
                              });
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                    ];
                  },
                ),
              ),
              
              // Floating Toolbar
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _toolButton(null, Icons.back_hand_rounded, 'Pan/Zoom'),
                        const VerticalDivider(width: 12),
                        _toolButton(PdfTool.pen, Icons.edit_rounded, 'Pen'),
                        _toolButton(PdfTool.highlighter, Icons.border_color_rounded, 'Highlight'),
                        _toolButton(PdfTool.eraser, Icons.auto_fix_normal_rounded, 'Eraser'),
                        const VerticalDivider(width: 24),
                        _colorButton(Colors.red),
                        _colorButton(Colors.blue),
                        _colorButton(Colors.green),
                        _colorButton(Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              
              if (_isSaving)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _toolButton(PdfTool? tool, IconData icon, String label) {
    final isSelected = tool == null ? _isReadOnly : (_currentTool == tool && !_isReadOnly);
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.blue : null),
      onPressed: () {
        setState(() {
          if (tool == null) {
            _isReadOnly = true;
          } else {
            _currentTool = tool;
            _isReadOnly = false;
          }
        });
      },
      tooltip: label,
    );
  }

  Widget _colorButton(Color color) {
    final isSelected = _currentColor == color;
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
        ),
      ),
    );
  }

  Widget _buildStickyNoteWidget(PdfStickyNote note) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => setState(() => _stickyNotes.remove(note)),
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
            ],
          ),
          TextField(
            controller: note.controller,
            maxLines: null,
            style: const TextStyle(fontSize: 12, color: Colors.black),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Type note...',
            ),
            onChanged: (val) => note.content = val,
          ),
        ],
      ),
    );
  }
}

class _StaticAnnotationPainter extends CustomPainter {
  final model.PdfAnnotation annotation;

  _StaticAnnotationPainter({required this.annotation});

  @override
  void paint(Canvas canvas, Size size) {
    if (annotation.points != null && annotation.points!.length > 1) {
      final paint = Paint()
        ..color = Color(annotation.colorValue)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = annotation.strokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(annotation.points![0].x, annotation.points![0].y);
      for (int i = 1; i < annotation.points!.length; i++) {
        path.lineTo(annotation.points![i].x, annotation.points![i].y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticAnnotationPainter oldDelegate) => false;
}
