import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

const _uuid = Uuid();

class BoardProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  Note? _activeNote;
  Note? get activeNote => _activeNote;

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  BoardPage? get currentPage =>
      _activeNote != null && _activeNote!.pages.isNotEmpty
          ? _activeNote!.pages[_currentPageIndex]
          : null;

  // Drawing state
  DrawingTool _tool = DrawingTool.pen;
  DrawingTool get tool => _tool;

  Color _penColor = const Color(0xFF1A1A2E);
  Color get penColor => _penColor;

  double _penWidth = 3.0;
  double get penWidth => _penWidth;

  List<DrawnStroke> _currentStroke = [];
  bool _isDrawing = false;

  // Text mode
  bool _textMode = false;
  bool get textMode => _textMode;

  // Text styling
  double _textFontSize = 18.0;
  double get textFontSize => _textFontSize;
  bool _textBold = false;
  bool get textBold => _textBold;
  bool _textItalic = false;
  bool get textItalic => _textItalic;

  Future<void> init() async {
    await _loadNotes();
  }

  // ═══ Note Management ════════════════════════════════════════════════════

  Future<Note> createNote({
    required String title,
    required String category,
    required int pageCount,
    required Color coverColor,
  }) async {
    final note = Note(
      id: _uuid.v4(),
      title: title,
      category: category,
      coverColor: coverColor,
    );
    for (int i = 0; i < pageCount; i++) {
      note.pages.add(BoardPage(
        id: _uuid.v4(),
        title: 'صفحة ${i + 1}',
      ));
    }
    _notes.add(note);
    await _saveNotes();
    notifyListeners();
    return note;
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    if (_activeNote?.id == id) {
      _activeNote = null;
      _currentPageIndex = 0;
    }
    await _saveNotes();
    notifyListeners();
  }

  void openNote(Note note) {
    _activeNote = note;
    _currentPageIndex = 0;
    notifyListeners();
  }

  void closeNote() {
    _activeNote = null;
    _currentPageIndex = 0;
    notifyListeners();
  }

  // ═══ Page Navigation ════════════════════════════════════════════════════

  void goToPage(int index) {
    if (_activeNote == null) return;
    if (index < 0 || index >= _activeNote!.pages.length) return;
    _currentPageIndex = index;
    notifyListeners();
  }

  void nextPage() => goToPage(_currentPageIndex + 1);
  void prevPage() => goToPage(_currentPageIndex - 1);

  bool get canGoNext =>
      _activeNote != null &&
      _currentPageIndex < _activeNote!.pages.length - 1;
  bool get canGoPrev => _currentPageIndex > 0;

  Future<void> addPage() async {
    if (_activeNote == null) return;
    _activeNote!.pages.add(BoardPage(
      id: _uuid.v4(),
      title: 'صفحة ${_activeNote!.pages.length + 1}',
    ));
    _currentPageIndex = _activeNote!.pages.length - 1;
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> updatePageTitle(String title) async {
    if (currentPage == null) return;
    currentPage!.title = title;
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> setPageBackground(Color color) async {
    if (currentPage == null) return;
    currentPage!.backgroundColor = color;
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> setPageLineStyle(PageLineStyle style) async {
    if (currentPage == null) return;
    currentPage!.lineStyle = style;
    await _saveActiveNote();
    notifyListeners();
  }

  // ═══ Drawing ════════════════════════════════════════════════════════════

  void setTool(DrawingTool t) {
    _tool = t;
    _textMode = false;
    notifyListeners();
  }

  void setPenColor(Color c) {
    _penColor = c;
    notifyListeners();
  }

  void setPenWidth(double w) {
    _penWidth = w;
    notifyListeners();
  }

  void startStroke(Offset point) {
    if (currentPage == null) return;
    _isDrawing = true;
    Color strokeColor;
    double strokeWidth;
    bool isHighlighter = false;

    if (_tool == DrawingTool.eraser) {
      strokeColor = currentPage!.backgroundColor;
      strokeWidth = _penWidth * 6;
    } else if (_tool == DrawingTool.highlighter) {
      strokeColor = _penColor.withOpacity(0.35);
      strokeWidth = _penWidth * 5;
      isHighlighter = true;
    } else {
      strokeColor = _penColor;
      strokeWidth = _penWidth;
    }

    _currentStroke = [
      DrawnStroke(
        points: [point],
        color: strokeColor,
        width: strokeWidth,
        isEraser: _tool == DrawingTool.eraser,
        isHighlighter: isHighlighter,
      )
    ];
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (!_isDrawing || _currentStroke.isEmpty) return;
    final stroke = _currentStroke.last;
    _currentStroke = [
      DrawnStroke(
        points: [...stroke.points, point],
        color: stroke.color,
        width: stroke.width,
        isEraser: stroke.isEraser,
        isHighlighter: stroke.isHighlighter,
      )
    ];
    notifyListeners();
  }

  Future<void> endStroke() async {
    if (!_isDrawing || currentPage == null) return;
    _isDrawing = false;
    if (_currentStroke.isNotEmpty) {
      currentPage!.strokes.add(_currentStroke.last);
      _currentStroke = [];
      await _saveActiveNote();
    }
    notifyListeners();
  }

  List<DrawnStroke> get allStrokes {
    if (currentPage == null) return [];
    return [...currentPage!.strokes, ..._currentStroke];
  }

  Future<void> clearPage() async {
    if (currentPage == null) return;
    currentPage!.strokes.clear();
    currentPage!.textNotes.clear();
    currentPage!.imageNotes.clear();
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> undoLastStroke() async {
    if (currentPage == null || currentPage!.strokes.isEmpty) return;
    currentPage!.strokes.removeLast();
    await _saveActiveNote();
    notifyListeners();
  }

  // ═══ Text Notes ══════════════════════════════════════════════════════════

  void toggleTextMode() {
    _textMode = !_textMode;
    if (_textMode) _tool = DrawingTool.pen;
    notifyListeners();
  }

  void setTextFontSize(double size) {
    _textFontSize = size;
    notifyListeners();
  }

  void setTextBold(bool v) {
    _textBold = v;
    notifyListeners();
  }

  void setTextItalic(bool v) {
    _textItalic = v;
    notifyListeners();
  }

  Future<void> addTextNote(String text, Offset position) async {
    if (currentPage == null || text.isEmpty) return;
    currentPage!.textNotes.add(TextNote(
      id: _uuid.v4(),
      text: text,
      position: position,
      color: _penColor,
      fontSize: _textFontSize,
      bold: _textBold,
      italic: _textItalic,
    ));
    _textMode = false;
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> updateTextNote(String id, String newText, Color color,
      double fontSize, bool bold, bool italic) async {
    if (currentPage == null) return;
    final note = currentPage!.textNotes.firstWhere((t) => t.id == id);
    note.text = newText;
    note.color = color;
    note.fontSize = fontSize;
    note.bold = bold;
    note.italic = italic;
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> deleteTextNote(String id) async {
    if (currentPage == null) return;
    currentPage!.textNotes.removeWhere((t) => t.id == id);
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> moveTextNote(String id, Offset newPos) async {
    if (currentPage == null) return;
    final note = currentPage!.textNotes.firstWhere((t) => t.id == id);
    note.position = newPos;
    await _saveActiveNote();
    notifyListeners();
  }

  // ═══ Image Notes ══════════════════════════════════════════════════════════

  Future<void> addImageNote(String imagePath, Offset position) async {
    if (currentPage == null) return;
    currentPage!.imageNotes.add(ImageNote(
      id: _uuid.v4(),
      imagePath: imagePath,
      position: position,
      width: 220,
      height: 160,
    ));
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> deleteImageNote(String id) async {
    if (currentPage == null) return;
    currentPage!.imageNotes.removeWhere((i) => i.id == id);
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> resizeImageNote(String id, double w, double h) async {
    if (currentPage == null) return;
    final img = currentPage!.imageNotes.firstWhere((i) => i.id == id);
    img.width = w.clamp(60, 800);
    img.height = h.clamp(60, 800);
    await _saveActiveNote();
    notifyListeners();
  }

  Future<void> moveImageNote(String id, Offset newPos) async {
    if (currentPage == null) return;
    final img = currentPage!.imageNotes.firstWhere((i) => i.id == id);
    img.position = newPos;
    await _saveActiveNote();
    notifyListeners();
  }

  // ═══ PDF ════════════════════════════════════════════════════════════════

  Future<void> attachPdf(String path) async {
    if (currentPage == null) return;
    currentPage!.pdfPath = path;
    currentPage!.pdfPage = 0;
    await _saveActiveNote();
    notifyListeners();
  }

  // ═══ Persistence ════════════════════════════════════════════════════════

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('note_ids') ?? [];
    _notes = [];
    for (final key in keys) {
      final data = prefs.getString('note_$key');
      if (data != null) {
        try {
          _notes.add(Note.fromJsonString(data));
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('note_ids', _notes.map((n) => n.id).toList());
    for (final note in _notes) {
      await prefs.setString('note_${note.id}', note.toJsonString());
    }
  }

  Future<void> _saveActiveNote() async {
    if (_activeNote == null) return;
    _activeNote!.updatedAt = DateTime.now();
    final idx = _notes.indexWhere((n) => n.id == _activeNote!.id);
    if (idx >= 0) _notes[idx] = _activeNote!;
    await _saveNotes();
  }
}

enum DrawingTool { pen, highlighter, eraser }
