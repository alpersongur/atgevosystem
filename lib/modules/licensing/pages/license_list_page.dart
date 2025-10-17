import 'package:flutter/material.dart';

import '../models/license_model.dart';
import '../services/license_service.dart';
import '../widgets/license_card.dart';
import 'license_detail_page.dart';
import 'license_edit_page.dart';

class LicenseListPageArgs {
  const LicenseListPageArgs({required this.companyId, this.companyName});

  final String companyId;
  final String? companyName;
}

class LicenseListPage extends StatelessWidget {
  const LicenseListPage({super.key, required this.companyId, this.companyName});

  static const routeName = '/superadmin/licenses';

  final String companyId;
  final String? companyName;

  @override
  Widget build(BuildContext context) {
    final title = companyName != null
        ? 'Lisanslar • ${companyName!}'
        : 'Firma Lisansları';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).pushNamed(
            LicenseEditPage.routeName,
            arguments: LicenseEditPageArgs(companyId: companyId),
          );
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lisans kaydı oluşturuldu.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Lisans'),
      ),
      body: StreamBuilder<List<LicenseModel>>(
        stream: LicenseService.instance.getLicenses(companyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lisanslar yüklenemedi: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final licenses = snapshot.data ?? const <LicenseModel>[];
          if (licenses.isEmpty) {
            return const Center(
              child: Text('Bu firmaya ait lisans kaydı bulunmuyor.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: licenses.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final license = licenses[index];
              return LicenseCard(
                license: license,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    LicenseDetailPage.routeName,
                    arguments: LicenseDetailPageArgs(
                      companyId: companyId,
                      licenseId: license.id,
                      companyName: companyName,
                    ),
                  );
                },
                onEdit: () {
                  Navigator.of(context).pushNamed(
                    LicenseEditPage.routeName,
                    arguments: LicenseEditPageArgs(
                      companyId: companyId,
                      editLicense: license,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
