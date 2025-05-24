import 'package:flutter/material.dart';
import 'package:vru_safety_app/utils/instruction_icons.dart';

class InstructionBar extends StatelessWidget {
  final List<dynamic> instructions;
  const InstructionBar({super.key, required this.instructions});

  @override
  Widget build(BuildContext context) {
    if (instructions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleCount = 1; // Show only the next instruction
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < visibleCount && i < instructions.length; i++) ...[
            Icon(
              iconForInstruction('${instructions[i]['sign']}'),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${instructions[i]['text']} (${(instructions[i]['distance'] as num).toStringAsFixed(0)} m)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          if (instructions.length > 1)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More instructions view not implemented yet.')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('More'),
            ),
        ],
      ),
    );
  }
}
