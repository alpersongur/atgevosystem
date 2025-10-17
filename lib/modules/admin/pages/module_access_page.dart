import 'package:flutter/material.dart';

import '../models/module_access_model.dart';
import '../services/module_access_service.dart';
import '../widgets/module_access_switch.dart';

class ModuleAccessPage extends StatefulWidget {
  const ModuleAccessPage({super.key});

  static const routeName = '/admin/modules';

  @override
  State<ModuleAccessPage> createState() => _ModuleAccessPageState();
}

class _ModuleAccessPageState extends State<ModuleAccessPage> {
  final ModuleAccessService _service = ModuleAccessService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modül Erişimleri')),
      body: StreamBuilder<List<ModuleAccessModel>>(
        stream: _service.getModulesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Modüller yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final modules = snapshot.data ?? <ModuleAccessModel>[];
          if (modules.isEmpty) {
            return const Center(child: Text('Sistem modülü bulunamadı.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: modules.length,
            itemBuilder: (_, index) {
              final module = modules[index];
              return ModuleAccessSwitch(
                module: module,
                onChanged: (value) =>
                    _service.toggleModuleActive(module.id, value),
              );
            },
          );
        },
      ),
    );
  }
}
