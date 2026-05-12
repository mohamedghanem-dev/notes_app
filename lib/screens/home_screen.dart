import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import '../models/models.dart';
import 'board_screen.dart';
import 'ebook_builder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();
    final notes = provider.notes;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories_outlined),
            tooltip: 'كتاب إلكتروني',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EbookBuilderScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: notes.isEmpty ? _buildEmpty(context) : _buildGrid(context, notes),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF533483),
        foregroundColor: Colors.white,
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('مذكرة جديدة'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_alt_outlined, size: 50, color: Color(0xFF533483)),
          ),
          const SizedBox(height: 20),
          const Text('لا توجد مذكرات بعد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('اضغط + لإنشاء مذكرة جديدة',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF533483),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('ابدأ الآن', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisExtent: 180,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: notes.length,
        itemBuilder: (ctx, i) => _NoteCard(note: notes[i]),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _CreateNoteDialog());
  }
}

// ─── Note Card ──────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BoardProvider>();

    return GestureDetector(
      onTap: () {
        provider.openNote(note);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: note.coverColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: note.coverColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${note.pages.length} صفحة',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('حذف المذكرة؟'),
                          content: const Text('هيتحذف كل حاجة في المذكرة دي.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await provider.deleteNote(note.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Row(
                      children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('حذف المذكرة', style: TextStyle(color: Colors.red))],
                    )),
                  ],
                ),
              ],
            ),
            const Spacer(),
            if (note.category.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(note.category, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ),
            Text(
              note.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(note.updatedAt),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Create Note Dialog ──────────────────────────────────────────────────────
class _CreateNoteDialog extends StatefulWidget {
  const _CreateNoteDialog();
  @override
  State<_CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<_CreateNoteDialog> {
  final _titleCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  int _pageCount = 5;
  Color _color = const Color(0xFF533483);

  final List<Color> _palette = [
    const Color(0xFF533483),
    const Color(0xFF1A1A2E),
    const Color(0xFF0F3460),
    const Color(0xFF1B4332),
    const Color(0xFF7B2D8B),
    const Color(0xFFB5451B),
    const Color(0xFF1A535C),
    const Color(0xFF3D405B),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('مذكرة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'عنوان المذكرة *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _catCtrl,
              decoration: InputDecoration(
                labelText: 'التصنيف (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Text('عدد الصفحات: $_pageCount',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Slider(
              value: _pageCount.toDouble(),
              min: 1, max: 50, divisions: 49,
              label: '$_pageCount',
              activeColor: _color,
              onChanged: (v) => setState(() => _pageCount = v.round()),
            ),
            const SizedBox(height: 8),
            const Text('لون الغلاف:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _palette.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == c ? Colors.black54 : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _create,
          child: const Text('إنشاء'),
        ),
      ],
    );
  }

  void _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final provider = context.read<BoardProvider>();
    final note = await provider.createNote(
      title: _titleCtrl.text.trim(),
      category: _catCtrl.text.trim(),
      pageCount: _pageCount,
      coverColor: _color,
    );
    if (mounted) {
      Navigator.pop(context);
      provider.openNote(note);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardScreen()));
    }
  }
}
