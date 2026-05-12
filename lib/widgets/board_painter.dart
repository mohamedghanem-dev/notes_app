import 'package:flutter/material.dart';
import '../models/models.dart';

// ─── Page Background ─────────────────────────────────────────────────────────
class PageBackgroundPainter extends CustomPainter {
  final PageLineStyle style;
  final Color lineColor;
  final Color bgColor;

  PageBackgroundPainter({
    required this.style,
    this.lineColor = const Color(0xFFD0D0E8),
    this.bgColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bgColor);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.7;

    switch (style) {
      case PageLineStyle.ruled:
        _drawRuled(canvas, size, paint);
        break;
      case PageLineStyle.grid:
        _drawGrid(canvas, size, paint);
        break;
      case PageLineStyle.dotted:
        _drawDotted(canvas, size, paint);
        break;
      case PageLineStyle.plain:
        break;
    }

    // Red margin line
    canvas.drawLine(
      const Offset(64, 0),
      Offset(64, size.height),
      Paint()..color = const Color(0xFFFFB3B3)..strokeWidth = 1.2,
    );
  }

  void _drawRuled(Canvas canvas, Size size, Paint paint) {
    const spacing = 38.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    const spacing = 38.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawDotted(Canvas canvas, Size size, Paint paint) {
    const spacing = 38.0;
    final dotPaint = Paint()..color = lineColor..style = PaintingStyle.fill;
    for (double y = spacing; y < size.height; y += spacing) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(PageBackgroundPainter old) =>
      old.style != style || old.bgColor != bgColor;
}

// ─── Strokes Painter ─────────────────────────────────────────────────────────
class StrokesPainter extends CustomPainter {
  final List<DrawnStroke> strokes;

  StrokesPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Save layer so eraser BlendMode.clear works correctly
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        paint.blendMode = BlendMode.clear;
      } else if (stroke.isHighlighter) {
        paint.blendMode = BlendMode.multiply;
      } else {
        paint.blendMode = BlendMode.srcOver;
      }

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2,
            paint..style = PaintingStyle.fill);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length - 1; i++) {
          final mid = Offset(
            (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
            (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(
              stroke.points[i].dx, stroke.points[i].dy, mid.dx, mid.dy);
        }
        path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(StrokesPainter old) => true;
}
