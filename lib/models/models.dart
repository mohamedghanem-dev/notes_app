import 'dart:convert';
import 'dart:ui';

// ─── Stroke ────────────────────────────────────────────────────────────────
class DrawnStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final bool isHighlighter;

  DrawnStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
    this.isHighlighter = false,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': color.value,
        'width': width,
        'isEraser': isEraser,
        'isHighlighter': isHighlighter,
      };

  factory DrawnStroke.fromJson(Map<String, dynamic> j) => DrawnStroke(
        points: (j['points'] as List)
            .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
            .toList(),
        color: Color(j['color']),
        width: (j['width'] as num).toDouble(),
        isEraser: j['isEraser'] ?? false,
        isHighlighter: j['isHighlighter'] ?? false,
      );
}

// ─── TextNote ──────────────────────────────────────────────────────────────
class TextNote {
  final String id;
  String text;
  Offset position;
  Color color;
  double fontSize;
  bool bold;
  bool italic;

  TextNote({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    this.fontSize = 18,
    this.bold = false,
    this.italic = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': position.dx,
        'y': position.dy,
        'color': color.value,
        'fontSize': fontSize,
        'bold': bold,
        'italic': italic,
      };

  factory TextNote.fromJson(Map<String, dynamic> j) => TextNote(
        id: j['id'],
        text: j['text'],
        position: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        color: Color(j['color']),
        fontSize: (j['fontSize'] as num?)?.toDouble() ?? 18,
        bold: j['bold'] ?? false,
        italic: j['italic'] ?? false,
      );
}

// ─── ImageNote ─────────────────────────────────────────────────────────────
class ImageNote {
  final String id;
  String imagePath;
  Offset position;
  double width;
  double height;

  ImageNote({
    required this.id,
    required this.imagePath,
    required this.position,
    this.width = 200,
    this.height = 150,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'x': position.dx,
        'y': position.dy,
        'width': width,
        'height': height,
      };

  factory ImageNote.fromJson(Map<String, dynamic> j) => ImageNote(
        id: j['id'],
        imagePath: j['imagePath'],
        position: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        width: (j['width'] as num?)?.toDouble() ?? 200,
        height: (j['height'] as num?)?.toDouble() ?? 150,
      );
}

// ─── BoardPage ─────────────────────────────────────────────────────────────
class BoardPage {
  final String id;
  String title;
  List<DrawnStroke> strokes;
  List<TextNote> textNotes;
  List<ImageNote> imageNotes;
  PageLineStyle lineStyle;
  Color backgroundColor;
  String? pdfPath;        // path to attached PDF
  int? pdfPage;           // which PDF page is shown

  BoardPage({
    required this.id,
    this.title = '',
    List<DrawnStroke>? strokes,
    List<TextNote>? textNotes,
    List<ImageNote>? imageNotes,
    this.lineStyle = PageLineStyle.ruled,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.pdfPath,
    this.pdfPage,
  })  : strokes = strokes ?? [],
        textNotes = textNotes ?? [],
        imageNotes = imageNotes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'textNotes': textNotes.map((t) => t.toJson()).toList(),
        'imageNotes': imageNotes.map((i) => i.toJson()).toList(),
        'lineStyle': lineStyle.index,
        'backgroundColor': backgroundColor.value,
        'pdfPath': pdfPath,
        'pdfPage': pdfPage,
      };

  factory BoardPage.fromJson(Map<String, dynamic> j) => BoardPage(
        id: j['id'],
        title: j['title'] ?? '',
        strokes: (j['strokes'] as List? ?? [])
            .map((s) => DrawnStroke.fromJson(s))
            .toList(),
        textNotes: (j['textNotes'] as List? ?? [])
            .map((t) => TextNote.fromJson(t))
            .toList(),
        imageNotes: (j['imageNotes'] as List? ?? [])
            .map((i) => ImageNote.fromJson(i))
            .toList(),
        lineStyle: PageLineStyle.values[j['lineStyle'] ?? 0],
        backgroundColor: Color(j['backgroundColor'] ?? 0xFFFFFFFF),
        pdfPath: j['pdfPath'],
        pdfPage: j['pdfPage'],
      );
}

enum PageLineStyle { ruled, grid, plain, dotted }

// ─── Note (مجموعة صفحات = مذكرة) ─────────────────────────────────────────
class Note {
  final String id;
  String title;
  String category;
  List<BoardPage> pages;
  DateTime createdAt;
  DateTime updatedAt;
  Color coverColor;

  Note({
    required this.id,
    required this.title,
    this.category = '',
    List<BoardPage>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.coverColor = const Color(0xFF533483),
  })  : pages = pages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'pages': pages.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'coverColor': coverColor.value,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'],
        title: j['title'],
        category: j['category'] ?? '',
        pages: (j['pages'] as List? ?? [])
            .map((p) => BoardPage.fromJson(p))
            .toList(),
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        coverColor: Color(j['coverColor'] ?? 0xFF533483),
      );

  String toJsonString() => jsonEncode(toJson());
  factory Note.fromJsonString(String s) => Note.fromJson(jsonDecode(s));
}
