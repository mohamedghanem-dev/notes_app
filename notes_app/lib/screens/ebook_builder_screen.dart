import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/board_provider.dart';

// ─── Simple Ebook Builder ─────────────────────────────────────────────────────
// Lets the user build a formatted ebook from their notes and export as PDF

class EbookBuilderScreen extends StatefulWidget {
  const EbookBuilderScreen({super.key});
  @override
  State<EbookBuilderScreen> createState() => _EbookBuilderScreenState();
}

class _EbookBuilderScreenState extends State<EbookBuilderScreen> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final List<_EbookSection> _sections = [];
  String _theme = 'dark';
  bool _exporting = false;

  final List<Map<String, dynamic>> _themes = [
    {'key': 'dark',  'label': 'داكن',   'bg': const Color(0xFF1A1A2E), 'fg': Colors.white},
    {'key': 'light', 'label': 'فاتح',   'bg': Colors.white,            'fg': Colors.black},
    {'key': 'warm',  'label': 'دافئ',   'bg': const Color(0xFFFFF8F0), 'fg': const Color(0xFF3B2A1A)},
    {'key': 'green', 'label': 'أخضر',   'bg': const Color(0xFF0D2B1D), 'fg': Colors.white},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTheme = _themes.firstWhere((t) => t['key'] == _theme);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('📖 كتاب إلكتروني', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            label: const Text('تصدير PDF', style: TextStyle(color: Colors.white)),
            onPressed: _exporting ? null : _export,
          ),
        ],
      ),
      body: Row(
        children: [
          // ─── Left: Editor ─────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Book info card
                _Card(
                  title: 'معلومات الكتاب',
                  child: Column(
                    children: [
                      _field(_titleCtrl, 'عنوان الكتاب *'),
                      const SizedBox(height: 10),
                      _field(_authorCtrl, 'اسم المؤلف'),
                      const SizedBox(height: 14),
                      const Align(alignment: Alignment.centerRight,
                          child: Text('ثيم الكتاب:', style: TextStyle(fontWeight: FontWeight.w500))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _themes.map((t) => ChoiceChip(
                          label: Text(t['label'] as String),
                          selected: _theme == t['key'],
                          selectedColor: const Color(0xFF533483),
                          labelStyle: TextStyle(
                            color: _theme == t['key'] ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) => setState(() => _theme = t['key'] as String),
                        )).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Sections
                ..._sections.asMap().entries.map((e) => _SectionCard(
                  section: e.value,
                  index: e.key,
                  onDelete: () => setState(() => _sections.removeAt(e.key)),
                  onUpdate: () => setState(() {}),
                )),

                const SizedBox(height: 12),

                // Add section button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Color(0xFF533483)),
                    foregroundColor: const Color(0xFF533483),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => setState(() => _sections.add(_EbookSection())),
                  icon: const Icon(Icons.add),
                  label: const Text('أضف فصل / قسم'),
                ),

                const SizedBox(height: 12),

                // Import from notes
                _Card(
                  title: 'استيراد من مذكراتك',
                  child: _ImportFromNotes(onImport: (text, title) {
                    setState(() => _sections.add(_EbookSection(title: title, content: text)));
                  }),
                ),
              ],
            ),
          ),

          // ─── Right: Preview ───────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedTheme['bg'] as Color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      Text(
                        _titleCtrl.text.isEmpty ? 'عنوان الكتاب' : _titleCtrl.text,
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold,
                          color: selectedTheme['fg'] as Color,
                        ),
                      ),
                      if (_authorCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_authorCtrl.text,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: (selectedTheme['fg'] as Color).withOpacity(0.6))),
                        ),
                      const SizedBox(height: 24),
                      Divider(color: (selectedTheme['fg'] as Color).withOpacity(0.2)),
                      const SizedBox(height: 16),
                      // Sections preview
                      ..._sections.map((s) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s.title.isNotEmpty)
                            Text(s.title,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold,
                                    color: selectedTheme['fg'] as Color)),
                          const SizedBox(height: 8),
                          Text(s.content.isEmpty ? '(محتوى الفصل)' : s.content,
                              style: TextStyle(
                                  fontSize: 13, height: 1.7,
                                  color: (selectedTheme['fg'] as Color).withOpacity(0.85))),
                          const SizedBox(height: 20),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
    );
  }

  Future<void> _export() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل عنوان الكتاب أولاً')));
      return;
    }
    setState(() => _exporting = true);

    final selectedTheme = _themes.firstWhere((t) => t['key'] == _theme);
    final bgColor = selectedTheme['bg'] as Color;
    final fgColor = selectedTheme['fg'] as Color;

    final doc = pw.Document();

    // Cover page
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Container(
        color: PdfColor.fromInt(bgColor.value),
        padding: const pw.EdgeInsets.all(60),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _titleCtrl.text,
              style: pw.TextStyle(
                fontSize: 36, fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(fgColor.value),
              ),
            ),
            if (_authorCtrl.text.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                _authorCtrl.text,
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColor.fromInt(fgColor.withOpacity(0.7).value),
                ),
              ),
            ],
          ],
        ),
      ),
    ));

    // Content pages
    for (final section in _sections) {
      if (section.title.isEmpty && section.content.isEmpty) continue;
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Container(
          color: PdfColor.fromInt(bgColor.value),
          padding: const pw.EdgeInsets.all(50),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (section.title.isNotEmpty) ...[
                pw.Text(
                  section.title,
                  style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(fgColor.value),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColor.fromInt(fgColor.withOpacity(0.25).value)),
                pw.SizedBox(height: 12),
              ],
              pw.Text(
                section.content,
                style: pw.TextStyle(
                  fontSize: 13, lineSpacing: 5,
                  color: PdfColor.fromInt(fgColor.withOpacity(0.88).value),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    setState(() => _exporting = false);
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}

// ─── Ebook Section Model ──────────────────────────────────────────────────────
class _EbookSection {
  String title;
  String content;
  _EbookSection({this.title = '', this.content = ''});
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _EbookSection section;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  const _SectionCard({required this.section, required this.index, required this.onDelete, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Card(
        title: 'فصل ${index + 1}',
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(text: section.title)
                ..selection = TextSelection.collapsed(offset: section.title.length),
              onChanged: (v) { section.title = v; onUpdate(); },
              decoration: InputDecoration(
                labelText: 'عنوان الفصل',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: section.content)
                ..selection = TextSelection.collapsed(offset: section.content.length),
              onChanged: (v) { section.content = v; onUpdate(); },
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'محتوى الفصل',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Import From Notes ────────────────────────────────────────────────────────
class _ImportFromNotes extends StatelessWidget {
  final void Function(String text, String title) onImport;
  const _ImportFromNotes({required this.onImport});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<BoardProvider>().notes;
    if (notes.isEmpty) {
      return const Text('لا يوجد مذكرات متاحة', style: TextStyle(color: Colors.grey));
    }
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: notes.map((note) => ActionChip(
        avatar: const Icon(Icons.note_alt_outlined, size: 16),
        label: Text(note.title, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          // Collect all text notes from all pages
          final text = note.pages
              .expand((p) => p.textNotes)
              .map((t) => t.text)
              .join('\n\n');
          onImport(text, note.title);
        },
      )).toList(),
    );
  }
}

// ─── Reusable Card ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
