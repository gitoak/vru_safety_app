import 'package:flutter/material.dart';

class InstructionBar extends StatefulWidget {
  final List<dynamic> instructions;
  const InstructionBar({super.key, required this.instructions});

  @override
  State<InstructionBar> createState() => _InstructionBarState();
}

class _InstructionBarState extends State<InstructionBar> {
  bool expanded = false;

  IconData _iconForInstruction(String sign) {
    switch (sign) {
      case '0':
        return Icons.arrow_upward; // continue
      case '1':
        return Icons.turn_slight_right;
      case '2':
        return Icons.turn_right;
      case '3':
        return Icons.turn_sharp_right;
      case '4':
        return Icons.rotate_right; // uturn right (fallback)
      case '-1':
        return Icons.turn_slight_left;
      case '-2':
        return Icons.turn_left;
      case '-3':
        return Icons.turn_sharp_left;
      case '-4':
        return Icons.rotate_left; // uturn left (fallback)
      case '5':
        return Icons.flag; // arrival
      default:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.instructions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleCount = expanded
        ? (widget.instructions.length < 4 ? widget.instructions.length : 4)
        : 1;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          for (int i = 0;
              i < visibleCount && i < widget.instructions.length;
              i++) ...[
            Icon(
              _iconForInstruction('${widget.instructions[i]['sign']}'),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${widget.instructions[i]['text']} (${(widget.instructions[i]['distance'] as num).toStringAsFixed(0)} m)',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (i < visibleCount - 1) const SizedBox(width: 16),
          ],
          const Spacer(),
          if (widget.instructions.length > 1)
            TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? 'Weniger' : 'Mehr'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
