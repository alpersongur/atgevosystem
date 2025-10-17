import 'package:flutter/material.dart';

import '../models/tenant_model.dart';
import '../services/tenant_service.dart';
import 'tenant_edit_page.dart';

class TenantDetailPageArgs {
  const TenantDetailPageArgs({required this.tenantId});

  final String tenantId;
}

class TenantDetailPage extends StatelessWidget {
  const TenantDetailPage({super.key, required this.tenantId});

  static const routeName = '/superadmin/tenants/detail';

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final tenantService = TenantService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Firma Detayı')),
      body: StreamBuilder<TenantModel?>(
        stream: tenantService.watchCompany(tenantId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Firma bilgileri yüklenemedi.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text('Firma bilgisi bulunamadı.'));
          }

          final tenant = snapshot.data!;

          return StreamBuilder<TenantModel?>(
            stream: tenantService.activeTenantStream,
            initialData: tenantService.activeTenant,
            builder: (context, activeSnapshot) {
              final activeTenant = activeSnapshot.data;
              final isSelected = activeTenant?.id == tenant.id;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tenant.companyName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Chip(
                          label: Text(tenant.isActive ? 'Aktif' : 'Pasif'),
                          backgroundColor: tenant.isActive
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Firebase Project ID',
                      value: tenant.firebaseProjectId.isEmpty
                          ? '-'
                          : tenant.firebaseProjectId,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Firma Sahibi',
                      value: tenant.ownerEmail.isEmpty
                          ? '-'
                          : tenant.ownerEmail,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Durum',
                      value: tenant.status.toUpperCase(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Modüller',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: tenant.modules.isEmpty
                          ? [
                              Chip(
                                label: const Text('Tanımlı modül bulunmuyor'),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                              ),
                            ]
                          : tenant.modules
                                .map(
                                  (module) => Chip(
                                    label: Text(module.toUpperCase()),
                                    avatar: const Icon(
                                      Icons.extension_outlined,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: tenant.isActive
                              ? () async {
                                  try {
                                    await tenantService
                                        .setActiveCompanyFromModel(tenant);
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
                                }
                              : null,
                          icon: Icon(
                            isSelected
                                ? Icons.check_circle_outline
                                : Icons.play_arrow_outlined,
                          ),
                          label: Text(
                            isSelected ? 'Aktif Firma' : 'Aktifleştir',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              TenantEditPage.routeName,
                              arguments: TenantEditPageArgs(editTenant: tenant),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Düzenle'),
                        ),
                        if (tenant.isActive)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.pause_circle_outline),
                            label: const Text('Pasifleştir'),
                            onPressed: () async {
                              await tenantService.deactivateCompany(tenant.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${tenant.companyName} pasifleştirildi.',
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        else
                          OutlinedButton.icon(
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Aktive Et'),
                            onPressed: () async {
                              await tenantService.activateCompany(tenant.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${tenant.companyName} aktif hale getirildi.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
