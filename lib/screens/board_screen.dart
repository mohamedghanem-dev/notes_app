import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../providers/board_provider.dart';
import '../models/models.dart';
import '../widgets/board_painter.dart';
import '../widgets/toolbar.dart';
import '../widgets/page_indicator.dart';
import '../widgets/text_note_layer.dart';
import '../widgets/image_note_layer.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _pageController = PageController();
  bool _showPageList = false;
  bool _showPdf = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();
    final note = provider.activeNote;
    if (note == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      appBar: _buildAppBar(context, provider, note),
      body: Column(
        children: [
          const BoardToolbar(),
          Expanded(
            child: Stack(
              children: [
                _buildPageView(provider, note),
                if (_showPageList) _buildPageListPanel(context, provider, note),
                const Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: PageIndicatorBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, BoardProvider provider, Note note) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () { provider.closeNote(); Navigator.pop(context); },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          if (note.category.isNotEmpty)
            Text(note.category,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
      actions: [
        // Insert image
        IconButton(
          icon: const Icon(Icons.image_outlined),
          tooltip: 'أضف صورة',
          onPressed: () => _pickImage(context, provider),
        ),
        // PDF options
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: 'PDF',
          onPressed: () => _showPdfMenu(context, provider),
        ),
        // Page list toggle
        IconButton(
          icon: Icon(_showPageList ? Icons.view_agenda : Icons.view_list),
          onPressed: () => setState(() => _showPageList = !_showPageList),
        ),
        // Add page
        IconButton(
          icon: const Icon(Icons.add_box_outlined),
          tooltip: 'صفحة جديدة',
          onPressed: () async {
            await provider.addPage();
            _pageController.animateToPage(
              provider.currentPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPageView(BoardProvider provider, Note note) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (i) => provider.goToPage(i),
      itemCount: note.pages.length,
      itemBuilder: (ctx, i) {
        final page = note.pages[i];
        if (page.pdfPath != null && _showPdf) {
          return _PdfViewPage(page: page, pageIndex: i);
        }
        return _DrawingPage(pageIndex: i);
      },
    );
  }

  Widget _buildPageListPanel(
      BuildContext context, BoardProvider provider, Note note) {
    return Positioned(
      top: 0, right: 0, bottom: 44,
      width: 110,
      child: Container(
        color: const Color(0xFF1A1A2E).withOpacity(0.95),
        child: ListView.builder(
          padding: const EdgeInsets.all(6),
          itemCount: note.pages.length,
          itemBuilder: (ctx, i) {
            final isCurrent = i == provider.currentPageIndex;
            return GestureDetector(
              onTap: () {
                provider.goToPage(i);
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                setState(() => _showPageList = false);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.white24 : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrent ? Border.all(color: Colors.white54) : null,
                ),
                child: Column(
                  children: [
                    Icon(Icons.article_outlined, color: Colors.white70, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      note.pages[i].title.isEmpty ? 'ص ${i + 1}' : note.pages[i].title,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, BoardProvider provider) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    // Copy to app docs for persistence
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/${picked.name}';
    await File(picked.path).copy(dest);
    if (mounted) {
      provider.addImageNote(dest, const Offset(60, 80));
    }
  }

  void _showPdfMenu(BuildContext context, BoardProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('خيارات PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded, color: Color(0xFF533483)),
              title: const Text('فتح PDF وتعديل عليه'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  provider.attachPdf(result.files.single.path!);
                  setState(() => _showPdf = true);
                }
              },
            ),
            if (provider.currentPage?.pdfPath != null)
              ListTile(
                leading: Icon(
                  _showPdf ? Icons.edit_note_rounded : Icons.picture_as_pdf_rounded,
                  color: const Color(0xFF533483),
                ),
                title: Text(_showPdf ? 'تبديل لوضع الرسم' : 'عرض PDF المرفق'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _showPdf = !_showPdf);
                },
              ),
            ListTile(
              leading: const Icon(Icons.print_rounded, color: Color(0xFF1B4332)),
              title: const Text('طباعة / تصدير كـ PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPdf(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, BoardProvider provider) async {
    final note = provider.activeNote;
    if (note == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تجهيز PDF...')),
    );

    final doc = pw.Document();
    for (final page in note.pages) {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(page.title.isEmpty ? 'صفحة' : page.title,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...page.textNotes.map((t) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(t.text,
                      style: pw.TextStyle(
                        fontSize: t.fontSize * 0.7,
                        fontWeight: t.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                        fontStyle: t.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
                      )),
                )),
          ],
        ),
      ));
    }

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}

// ─── Drawing Page ─────────────────────────────────────────────────────────────
class _DrawingPage extends StatelessWidget {
  final int pageIndex;
  const _DrawingPage({required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();
    final page = provider.activeNote!.pages[pageIndex];
    final isActive = provider.currentPageIndex == pageIndex;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 52),
      decoration: BoxDecoration(
        color: page.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background lines
            CustomPaint(
              painter: PageBackgroundPainter(
                style: page.lineStyle,
                bgColor: page.backgroundColor,
              ),
              size: Size.infinite,
            ),
            // Strokes layer
            if (isActive)
              Consumer<BoardProvider>(
                builder: (_, p, __) => CustomPaint(
                  painter: StrokesPainter(strokes: p.allStrokes),
                  size: Size.infinite,
                ),
              )
            else
              CustomPaint(
                painter: StrokesPainter(strokes: page.strokes),
                size: Size.infinite,
              ),
            // Image notes
            ImageNoteLayer(page: page, isActive: isActive),
            // Text notes
            TextNoteLayer(page: page, isActive: isActive),
            // Touch input
            if (isActive) _DrawingInput(),
            // Page title
            Positioned(
              top: 6, left: 72, right: 10,
              child: _PageTitleWidget(page: page),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drawing Input ────────────────────────────────────────────────────────────
class _DrawingInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<BoardProvider>();
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (!provider.textMode) provider.startStroke(e.localPosition);
      },
      onPointerMove: (e) {
        if (!provider.textMode) provider.addPoint(e.localPosition);
      },
      onPointerUp: (e) {
        if (!provider.textMode) {
          provider.endStroke();
        } else {
          _showTextInput(context, e.localPosition);
        }
      },
    );
  }

  void _showTextInput(BuildContext context, Offset position) {
    final provider = context.read<BoardProvider>();
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('أضف نص'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'اكتب هنا...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط مرتين على النص لتعديله • اسحبه للتحريك',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF533483),
                foregroundColor: Colors.white),
            onPressed: () {
              provider.addTextNote(ctrl.text, position);
              Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

// ─── PDF View Page ────────────────────────────────────────────────────────────
class _PdfViewPage extends StatelessWidget {
  final BoardPage page;
  final int pageIndex;
  const _PdfViewPage({required this.page, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            SfPdfViewer.file(File(page.pdfPath!)),
            // Annotation layer on top of PDF
            TextNoteLayer(page: page, isActive: true),
          ],
        ),
      ),
    );
  }
}

// ─── Page Title ───────────────────────────────────────────────────────────────
class _PageTitleWidget extends StatefulWidget {
  final BoardPage page;
  const _PageTitleWidget({required this.page});
  @override
  State<_PageTitleWidget> createState() => _PageTitleWidgetState();
}

class _PageTitleWidgetState extends State<_PageTitleWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.page.title);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return TextField(
        controller: _ctrl,
        autofocus: true,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        ),
        onSubmitted: (v) {
          context.read<BoardProvider>().updatePageTitle(v);
          setState(() => _editing = false);
        },
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.page.title.isEmpty ? 'اضغط لإضافة عنوان' : widget.page.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.page.title.isEmpty ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
}
