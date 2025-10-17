import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/permission_service.dart';
import '../widgets/permission_switch_cell.dart';

class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({super.key});

  static const routeName = '/admin/permissions';

  @override
  State<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  final Map<String, Map<String, Map<String, bool>>> _localPermissions = {};
  final List<String> _roles = const [
    'admin',
    'sales',
    'production',
    'accounting',
  ];
  final List<String> _actions = const ['read', 'write', 'update', 'delete'];

  bool _isSaving = false;

  void _setLocalPermission(
    String module,
    String role,
    String action,
    bool value,
  ) {
    _localPermissions.putIfAbsent(module, () => {});
    _localPermissions[module]!.putIfAbsent(role, () => {});
    _localPermissions[module]![role]![action] = value;
  }

  Future<void> _handleSave() async {
    if (_localPermissions.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final futures = _localPermissions.entries.map((moduleEntry) {
        final module = moduleEntry.key;
        final data = moduleEntry.value.map(
          (role, actions) => MapEntry(role, actions),
        );
        return AdminPermissionService.instance.updatePermission(module, data);
      });
      await Future.wait(futures);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İzinler kaydedildi')));
      _localPermissions.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İzinler kaydedilemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleAddModule() async {
    final controller = TextEditingController();
    final moduleName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Modül Ekle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Modül Adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(context).pop(value);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (moduleName == null || moduleName.isEmpty) return;

    try {
      await AdminPermissionService.instance.addModule(moduleName);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$moduleName modülü eklendi')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Modül eklenemedi: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İzin Yönetimi'),
        actions: [
          TextButton.icon(
            onPressed: _handleAddModule,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Modül Ekle',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminPermissionService.instance.getAllPermissions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('İzinler yüklenirken hata oluştu\n${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('İzin kaydı bulunmuyor.'));
          }

          final columns = <DataColumn>[const DataColumn(label: Text('Modül'))];
          for (final role in _roles) {
            for (final action in _actions) {
              columns.add(DataColumn(label: Text('$role\n$action')));
            }
          }

          final rows = docs.map((doc) {
            final moduleName = doc.id;
            final data = doc.data();

            final cells = <DataCell>[DataCell(Text(moduleName))];

            for (final role in _roles) {
              final roleData = data[role];
              for (final action in _actions) {
                final actionValue =
                    (roleData is Map && roleData[action] == true);
                cells.add(
                  DataCell(
                    PermissionSwitchCell(
                      value:
                          _localPermissions[moduleName]?[role]?[action] ??
                          actionValue,
                      onChanged: (value) {
                        setState(() {
                          _setLocalPermission(moduleName, role, action, value);
                        });
                      },
                    ),
                  ),
                );
              }
            }

            return DataRow(cells: cells);
          }).toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(columns: columns, rows: rows),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
