import 'package:flutter/material.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final bool isBottom;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                activeColor: Colors.orangeAccent,
                activeTrackColor: Colors.orangeAccent.withOpacity(0.3),
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (!isBottom)
          Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 20),
      ],
    );
  }
}
