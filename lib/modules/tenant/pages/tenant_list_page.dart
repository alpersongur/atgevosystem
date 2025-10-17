import 'package:flutter/material.dart';

import '../models/tenant_model.dart';
import '../services/tenant_service.dart';
import '../widgets/tenant_card.dart';
import 'tenant_detail_page.dart';
import 'tenant_edit_page.dart';

class TenantListPage extends StatelessWidget {
  const TenantListPage({super.key});

  static const routeName = '/superadmin/tenants';

  @override
  Widget build(BuildContext context) {
    final tenantService = TenantService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Firmalar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).pushNamed(TenantEditPage.routeName);
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yeni firma eklendi.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Firma'),
      ),
      body: StreamBuilder<List<TenantModel>>(
        stream: tenantService.getCompaniesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Firmalar yüklenirken hata oluştu.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tenants = snapshot.data ?? const <TenantModel>[];
          if (tenants.isEmpty) {
            return const Center(child: Text('Kayıtlı firma bulunmuyor.'));
          }

          return StreamBuilder<TenantModel?>(
            stream: tenantService.activeTenantStream,
            initialData: tenantService.activeTenant,
            builder: (context, activeSnapshot) {
              final activeTenant = activeSnapshot.data;

              return ListView.separated(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 96,
                ),
                itemCount: tenants.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tenant = tenants[index];
                  return TenantCard(
                    tenant: tenant,
                    isSelected: tenant.id == activeTenant?.id,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        TenantDetailPage.routeName,
                        arguments: TenantDetailPageArgs(tenantId: tenant.id),
                      );
                    },
                    onEdit: () {
                      Navigator.of(context).pushNamed(
                        TenantEditPage.routeName,
                        arguments: TenantEditPageArgs(editTenant: tenant),
                      );
                    },
                    onSelect: () async {
                      try {
                        await tenantService.setActiveCompanyFromModel(tenant);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${tenant.companyName} aktif firma olarak seçildi.',
                            ),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Firma aktifleştirilemedi: $error',
                            ),
                          ),
                        );
                      }
                    },
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
