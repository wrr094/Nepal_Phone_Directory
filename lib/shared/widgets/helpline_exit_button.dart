import 'package:flutter/material.dart';

class HelplineExitButton extends StatelessWidget {
  const HelplineExitButton({required this.onExit, super.key});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Exit Nepal HelpLine and return to NepAll',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton(onPressed: onExit, child: const Text('EXIT')),
      ),
    );
  }
}
