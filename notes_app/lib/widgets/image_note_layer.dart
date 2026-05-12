import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/board_provider.dart';

class ImageNoteLayer extends StatelessWidget {
  final BoardPage page;
  final bool isActive;
  const ImageNoteLayer({super.key, required this.page, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: page.imageNotes
          .map((img) => _ResizableImageNote(img: img, isActive: isActive))
          .toList(),
    );
  }
}

class _ResizableImageNote extends StatefulWidget {
  final ImageNote img;
  final bool isActive;
  const _ResizableImageNote({required this.img, required this.isActive});
  @override
  State<_ResizableImageNote> createState() => _ResizableImageNoteState();
}

class _ResizableImageNoteState extends State<_ResizableImageNote> {
  late Offset _pos;
  late double _w, _h;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _pos = widget.img.position;
    _w = widget.img.width;
    _h = widget.img.height;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selected = !_selected),
        onPanUpdate: widget.isActive
            ? (d) {
                setState(() => _pos += d.delta);
                context.read<BoardProvider>().moveImageNote(widget.img.id, _pos);
              }
            : null,
        onLongPress: widget.isActive ? () => _showOptions(context) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _w,
              height: _h,
              decoration: BoxDecoration(
                border: _selected
                    ? Border.all(color: const Color(0xFF533483), width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: File(widget.img.imagePath).existsSync()
                    ? Image.file(
                        File(widget.img.imagePath),
                        fit: BoxFit.cover,
                        width: _w,
                        height: _h,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            // Resize handle (bottom-right corner)
            if (_selected && widget.isActive)
              Positioned(
                right: -14,
                bottom: -14,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _w = (_w + d.delta.dx).clamp(60.0, 700.0);
                      _h = (_h + d.delta.dy).clamp(60.0, 700.0);
                    });
                    context.read<BoardProvider>()
                        .resizeImageNote(widget.img.id, _w, _h);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF533483),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.open_in_full, color: Colors.white, size: 14),
                  ),
                ),
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف الصورة', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<BoardProvider>().deleteImageNote(widget.img.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
