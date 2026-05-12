import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/board_provider.dart';
import '../models/models.dart';

class BoardToolbar extends StatelessWidget {
  const BoardToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();

    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Tools
            _ToolBtn(icon: Icons.edit_rounded, label: 'قلم',
                active: provider.tool == DrawingTool.pen && !provider.textMode,
                onTap: () => provider.setTool(DrawingTool.pen)),
            _ToolBtn(icon: Icons.highlight_rounded, label: 'تظليل',
                active: provider.tool == DrawingTool.highlighter,
                onTap: () => provider.setTool(DrawingTool.highlighter)),
            _ToolBtn(icon: Icons.text_fields_rounded, label: 'نص',
                active: provider.textMode,
                onTap: () => provider.toggleTextMode()),
            _ToolBtn(icon: Icons.auto_fix_normal_rounded, label: 'ممحاة',
                active: provider.tool == DrawingTool.eraser,
                onTap: () => provider.setTool(DrawingTool.eraser)),
            const _Sep(),

            // Color palette
            ...[
              const Color(0xFF1A1A2E), Colors.black, Colors.red,
              Colors.blue, Colors.green, Colors.orange,
              Colors.purple, Colors.teal,
            ].map((c) => _ColorDot(color: c)),
            _ColorPickerBtn(),
            const _Sep(),

            // Pen width
            const Icon(Icons.line_weight, color: Colors.white54, size: 16),
            SizedBox(
              width: 85,
              child: Slider(
                value: provider.penWidth.clamp(1.0, 20.0),
                min: 1, max: 20,
                activeColor: provider.penColor,
                inactiveColor: Colors.white24,
                onChanged: (v) => provider.setPenWidth(v),
              ),
            ),
            const _Sep(),

            // Text options (only visible in text mode)
            if (provider.textMode) ...[
              _ToolBtn(icon: Icons.format_bold, label: 'Bold',
                  active: provider.textBold,
                  onTap: () => provider.setTextBold(!provider.textBold)),
              _ToolBtn(icon: Icons.format_italic, label: 'Italic',
                  active: provider.textItalic,
                  onTap: () => provider.setTextItalic(!provider.textItalic)),
              const Icon(Icons.format_size, color: Colors.white54, size: 16),
              SizedBox(
                width: 70,
                child: Slider(
                  value: provider.textFontSize.clamp(10, 48),
                  min: 10, max: 48,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => provider.setTextFontSize(v),
                ),
              ),
              const _Sep(),
            ],

            // Actions
            _ToolBtn(icon: Icons.undo_rounded, label: 'تراجع',
                active: false,
                onTap: () => provider.undoLastStroke()),
            _ToolBtn(icon: Icons.delete_sweep_rounded, label: 'مسح',
                active: false,
                onTap: () => _confirmClear(context, provider)),
            const _Sep(),

            // Page style
            PopupMenuButton<PageLineStyle>(
              tooltip: 'نمط الصفحة',
              icon: const Icon(Icons.grid_4x4_rounded, color: Colors.white70, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (style) => provider.setPageLineStyle(style),
              itemBuilder: (_) => [
                const PopupMenuItem(value: PageLineStyle.ruled, child: Text('مسطّرة')),
                const PopupMenuItem(value: PageLineStyle.grid, child: Text('مربعات')),
                const PopupMenuItem(value: PageLineStyle.dotted, child: Text('نقاط')),
                const PopupMenuItem(value: PageLineStyle.plain, child: Text('فارغة')),
              ],
            ),

            // Page background color
            _BgColorBtn(),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, BoardProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مسح الصفحة؟'),
        content: const Text('هيتمسح كل اللي في الصفحة دي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { provider.clearPage(); Navigator.pop(context); },
            child: const Text('امسح'),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: Colors.white54) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();
    final isActive = provider.penColor.value == color.value;
    return GestureDetector(
      onTap: () => provider.setPenColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: isActive ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

class _ColorPickerBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 22, height: 22,
        decoration: BoxDecoration(
          gradient: const SweepGradient(colors: [
            Colors.red, Colors.yellow, Colors.green,
            Colors.cyan, Colors.blue, Colors.purple, Colors.red,
          ]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    final provider = context.read<BoardProvider>();
    Color picked = provider.penColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('اختر لون'),
        content: ColorPicker(pickerColor: picked, onColorChanged: (c) => picked = c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
            onPressed: () { provider.setPenColor(picked); Navigator.pop(context); },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

class _BgColorBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_color_fill_rounded, color: Colors.white70, size: 18),
            const Text('خلفية', style: TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    final provider = context.read<BoardProvider>();
    Color picked = provider.currentPage?.backgroundColor ?? Colors.white;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('لون خلفية الصفحة'),
        content: ColorPicker(pickerColor: picked, onColorChanged: (c) => picked = c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
            onPressed: () { provider.setPageBackground(picked); Navigator.pop(context); },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 1, height: 28,
        color: Colors.white.withOpacity(0.20),
      );
}
