import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final TextStyle? titleStyle;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: titleStyle ?? Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }
}
