import 'package:flutter/material.dart';

import '../../../modules/tenant/models/tenant_model.dart';
import '../../../modules/tenant/services/tenant_service.dart';
import '../services/api_keys_service.dart';

class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({super.key});

  static const routeName = '/admin/api-keys';

  @override
  State<ApiKeysPage> createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  String? _selectedCompanyId;
  TenantModel? _selectedTenant;
  final List<String> _availableScopes = const [
    'crm.read',
    'crm.write',
    'finance.read',
    'finance.write',
    'inventory.read',
    'inventory.write',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Anahtarları')),
      floatingActionButton: (_selectedCompanyId == null)
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleCreateKey,
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('Yeni Anahtar'),
            ),
      body: StreamBuilder<List<TenantModel>>(
        stream: TenantService.instance.getCompaniesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Firmalar yüklenemedi: ${snapshot.error}'),
            );
          }
          final tenants = snapshot.data ?? const [];
          if (tenants.isEmpty) {
            return const Center(child: Text('Kayıtlı firma bulunmuyor.'));
          }
          _selectedCompanyId ??= tenants.first.id;
          _selectedTenant ??= tenants.firstWhere(
            (tenant) => tenant.id == _selectedCompanyId,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Firma Seçin',
                    border: OutlineInputBorder(),
                  ),
                  items: tenants
                      .map(
                        (tenant) => DropdownMenuItem(
                          value: tenant.id,
                          child: Text(
                            tenant.companyName.isEmpty
                                ? tenant.id
                                : tenant.companyName,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCompanyId = value;
                      _selectedTenant = tenants.firstWhere(
                        (tenant) => tenant.id == value,
                      );
                    });
                  },
                ),
              ),
              Expanded(
                child: _selectedCompanyId == null
                    ? const SizedBox.shrink()
                    : StreamBuilder<List<ApiKeyRecord>>(
                        stream: ApiKeysService.instance.watchKeys(
                          _selectedCompanyId!,
                        ),
                        builder: (context, keySnapshot) {
                          if (keySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (keySnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Anahtarlar yüklenemedi: ${keySnapshot.error}',
                              ),
                            );
                          }
                          final keys = keySnapshot.data ?? const [];
                          if (keys.isEmpty) {
                            return const Center(
                              child: Text('Bu firmaya ait API anahtarı yok.'),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: keys.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final key = keys[index];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    'Anahtar ${key.last8 != null ? '...${key.last8}' : key.id}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Durum: ${key.status}'),
                                      Text(
                                        'Oluşturulma: ${key.createdAt.toLocal()}'
                                            .split('.')
                                            .first,
                                      ),
                                      Text(
                                        'Kapsamlar: ${key.scopes.isEmpty ? '-' : key.scopes.join(', ')}',
                                      ),
                                    ],
                                  ),
                                  trailing: key.status == 'revoked'
                                      ? const Icon(Icons.lock_outline)
                                      : IconButton(
                                          tooltip: 'Anahtarı İptal Et',
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                          ),
                                          onPressed: () =>
                                              _handleRevokeKey(key),
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCreateKey() async {
    final companyId = _selectedCompanyId;
    if (companyId == null) return;
    final scopes = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final selected = ValueNotifier<Set<String>>({});
        return AlertDialog(
          title: const Text('Yeni API Anahtarı'),
          content: SizedBox(
            width: 320,
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: selected,
              builder: (context, value, _) {
                return Wrap(
                  spacing: 8,
                  children: _availableScopes
                      .map(
                        (scope) => FilterChip(
                          label: Text(scope),
                          selected: value.contains(scope),
                          onSelected: (state) {
                            final copy = Set<String>.from(value);
                            if (state) {
                              copy.add(scope);
                            } else {
                              copy.remove(scope);
                            }
                            selected.value = copy;
                          },
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  selected.value.isEmpty
                      ? _availableScopes
                      : selected.value.toList(),
                );
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );

    if (!mounted || scopes == null) return;

    try {
      final result = await ApiKeysService.instance.createKey(companyId, scopes);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('API Anahtarı Oluşturuldu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu anahtarı güvenli şekilde saklayın. Bir daha görüntülenmeyecek.',
                ),
                const SizedBox(height: 12),
                SelectableText(result.plainKey),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Anahtar oluşturulamadı: $error')));
    }
  }

  Future<void> _handleRevokeKey(ApiKeyRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anahtarı iptal et'),
        content: Text('Anahtarı iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiKeysService.instance.revokeKey(record.companyId, record.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anahtar iptal edildi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anahtar iptal edilemedi: $error')),
      );
    }
  }
}
