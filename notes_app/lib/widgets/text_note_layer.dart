import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/board_provider.dart';

class TextNoteLayer extends StatelessWidget {
  final BoardPage page;
  final bool isActive;
  const TextNoteLayer({super.key, required this.page, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: page.textNotes
          .map((note) => _DraggableTextNote(note: note, isActive: isActive))
          .toList(),
    );
  }
}

class _DraggableTextNote extends StatefulWidget {
  final TextNote note;
  final bool isActive;
  const _DraggableTextNote({required this.note, required this.isActive});
  @override
  State<_DraggableTextNote> createState() => _DraggableTextNoteState();
}

class _DraggableTextNoteState extends State<_DraggableTextNote> {
  late Offset _pos;

  @override
  void initState() {
    super.initState();
    _pos = widget.note.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onPanUpdate: widget.isActive
            ? (d) {
                setState(() => _pos += d.delta);
                context.read<BoardProvider>().moveTextNote(widget.note.id, _pos);
              }
            : null,
        onDoubleTap: widget.isActive ? () => _showEditDialog(context) : null,
        onLongPress: widget.isActive ? () => _showOptions(context) : null,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.note.color.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 5,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Text(
            widget.note.text,
            style: TextStyle(
              color: widget.note.color,
              fontSize: widget.note.fontSize,
              fontWeight: widget.note.bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: widget.note.italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final provider = context.read<BoardProvider>();
    final ctrl = TextEditingController(text: widget.note.text);
    Color color = widget.note.color;
    double fontSize = widget.note.fontSize;
    bool bold = widget.note.bold;
    bool italic = widget.note.italic;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل النص'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    hintText: 'اكتب هنا...',
                  ),
                ),
                const SizedBox(height: 12),
                // Font size
                Row(
                  children: [
                    const Text('حجم: ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 10, max: 48,
                        activeColor: color,
                        onChanged: (v) => setState(() => fontSize = v),
                      ),
                    ),
                    Text('${fontSize.round()}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                // Bold / Italic
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Bold', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: bold,
                      onSelected: (v) => setState(() => bold = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Italic', style: TextStyle(fontStyle: FontStyle.italic)),
                      selected: italic,
                      onSelected: (v) => setState(() => italic = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Colors
                const Text('اللون:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    Colors.black, const Color(0xFF1A1A2E), Colors.red,
                    Colors.blue, Colors.green, Colors.orange, Colors.purple,
                    Colors.teal, Colors.brown,
                  ].map((c) => GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: Border.all(
                          color: color == c ? Colors.black : Colors.transparent,
                          width: 2.5,
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
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white),
              onPressed: () {
                provider.updateTextNote(
                    widget.note.id, ctrl.text, color, fontSize, bold, italic);
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل النص'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<BoardProvider>().deleteTextNote(widget.note.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
