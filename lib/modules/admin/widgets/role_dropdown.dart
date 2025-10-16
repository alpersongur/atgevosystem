import 'package:flutter/material.dart';

class RoleDropdown extends StatelessWidget {
  const RoleDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  static const List<String> roles = [
    'admin',
    'sales',
    'production',
    'accounting',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Rol'),
      items: roles
          .map(
            (role) => DropdownMenuItem(
              value: role,
              child: Text(role),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
