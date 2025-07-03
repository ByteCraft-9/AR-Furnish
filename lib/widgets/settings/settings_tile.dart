import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? value;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: value != null
          ? Text(
              value!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}