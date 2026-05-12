import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';

class PageIndicatorBar extends StatelessWidget {
  const PageIndicatorBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();
    final note = provider.activeNote;
    if (note == null) return const SizedBox.shrink();

    final total = note.pages.length;
    final current = provider.currentPageIndex;

    return Container(
      height: 44,
      color: const Color(0xFF1A1A2E).withOpacity(0.92),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            iconSize: 22,
            padding: EdgeInsets.zero,
            onPressed: provider.canGoPrev ? () => provider.prevPage() : null,
          ),
          GestureDetector(
            onTap: () => _showPagePicker(context, provider, total, current),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${current + 1} / $total',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            iconSize: 22,
            padding: EdgeInsets.zero,
            onPressed: provider.canGoNext ? () => provider.nextPage() : null,
          ),
        ],
      ),
    );
  }

  void _showPagePicker(BuildContext context, BoardProvider provider, int total, int current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SizedBox(
        height: 300,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('الصفحات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: total,
                itemBuilder: (ctx, i) => ListTile(
                  selected: i == current,
                  selectedColor: const Color(0xFF533483),
                  leading: CircleAvatar(
                    backgroundColor: i == current ? const Color(0xFF533483) : Colors.grey.shade200,
                    foregroundColor: i == current ? Colors.white : Colors.black87,
                    radius: 16,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(provider.activeNote!.pages[i].title.isEmpty
                      ? 'صفحة ${i + 1}'
                      : provider.activeNote!.pages[i].title),
                  onTap: () {
                    provider.goToPage(i);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
