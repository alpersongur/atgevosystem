import 'package:flutter/material.dart';

import '../models/module_access_model.dart';

class ModuleAccessSwitch extends StatelessWidget {
  const ModuleAccessSwitch({
    super.key,
    required this.module,
    required this.onChanged,
  });

  final ModuleAccessModel module;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(module.name),
        subtitle: Text(
          module.description.isEmpty
              ? 'Açıklama belirtilmemiş.'
              : module.description,
        ),
        trailing: Switch(value: module.isActive, onChanged: onChanged),
      ),
    );
  }
}
