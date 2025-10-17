import 'package:flutter/material.dart';

class PermissionSwitchCell extends StatelessWidget {
  const PermissionSwitchCell({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(value: value, onChanged: onChanged);
  }
}
