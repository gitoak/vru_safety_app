import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vru_safety_app/utils/instruction_icons.dart';

class InstructionBar extends StatefulWidget {
  final List<dynamic> initialInstructions;
  final Stream<List<dynamic>>? instructionStream;

  const InstructionBar({
    super.key,
    required this.initialInstructions,
    this.instructionStream,
  });

  @override
  _InstructionBarState createState() => _InstructionBarState();
}

class _InstructionBarState extends State<InstructionBar> {
  late List<dynamic> _instructions;
  StreamSubscription<List<dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _instructions = widget.initialInstructions;

    if (widget.instructionStream != null) {
      _subscription = widget.instructionStream!.listen((newInstructions) {
        setState(() {
          _instructions = newInstructions;
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_instructions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleCount = 1; // Show only the next instruction
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          for (
            int i = 0;
            i < visibleCount && i < _instructions.length;
            i++
          ) ...[
            Icon(
              iconForInstruction('${_instructions[i]['sign']}'),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${_instructions[i]['text']} (${(_instructions[i]['distance'] as num).toStringAsFixed(0)} m)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          if (_instructions.length > 1)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'More instructions view not implemented yet.',
                    ),
                  ),
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
