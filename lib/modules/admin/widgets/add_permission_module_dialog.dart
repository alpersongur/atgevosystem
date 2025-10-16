import 'package:flutter/material.dart';

import '../services/permission_service.dart';

class AddPermissionModuleDialog extends StatefulWidget {
  const AddPermissionModuleDialog({super.key});

  @override
  State<AddPermissionModuleDialog> createState() => _AddPermissionModuleDialogState();
}

class _AddPermissionModuleDialogState extends State<AddPermissionModuleDialog> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final moduleName = _controller.text.trim();
    if (moduleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modül adı boş olamaz')),  
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AdminPermissionService.instance.addModule(moduleName);
      if (!mounted) return;
      Navigator.of(context).pop(moduleName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modül eklenemedi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Modül Ekle'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Modül Adı'),
        onSubmitted: (_) => _handleSubmit(),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSubmit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ekle'),
        ),
      ],
    );
  }
}
