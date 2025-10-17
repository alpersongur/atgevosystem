import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/company_service.dart';
import '../../licensing/models/license_model.dart';
import '../../licensing/services/license_service.dart';
import '../../licensing/pages/license_list_page.dart';

class CompanyDetailPage extends StatelessWidget {
  const CompanyDetailPage({super.key, required this.companyId});

  final String companyId;

  static Route<dynamic> route(String companyId) {
    return MaterialPageRoute(
      builder: (_) => CompanyDetailPage(companyId: companyId),
      settings: RouteSettings(arguments: companyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şirket Detayı')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Şirket verileri yüklenemedi\n${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? {};
          final name = data['name'] as String? ?? 'Adsız Şirket';
          final projectId = data['projectId'] as String? ?? '---';
          final ownerEmail = data['owner_email'] as String? ?? '-';
          final modules = List<String>.from(data['modules'] as List? ?? []);
          final active = data['active'] != false;
          final usage = data['usage'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Project ID: $projectId'),
                        Text('Sahip E-posta: $ownerEmail'),
                        Text('Durum: ${active ? 'Aktif' : 'Pasif'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<LicenseModel?>(
                  future: LicenseService.instance.fetchActiveLicense(companyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final license = snapshot.data;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Lisans Bilgileri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      LicenseListPage.routeName,
                                      arguments: LicenseListPageArgs(
                                        companyId: companyId,
                                        companyName: name,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.verified_outlined),
                                  label: const Text('Lisans Yönetimi'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (license == null)
                              const Text(
                                'Aktif lisans bulunamadı. Süresi dolmuş olabilir.',
                              )
                            else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Modüller: ${license.modules.map((m) => m.toUpperCase()).join(', ')}',
                                    ),
                                  ),
                                  Chip(
                                    label: Text(license.status.toUpperCase()),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dönem: ${_formatDate(license.startDate)} - ${_formatDate(license.endDate)}',
                              ),
                              Text(
                                'Kalan Gün: ${license.remainingDays ?? '-'}',
                              ),
                              Text(
                                'Ücret: ${license.price.toStringAsFixed(2)} ${license.currency}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modüller',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (modules.isEmpty)
                          const Text('Modül tanımlı değil.')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: modules
                                .map(
                                  (module) =>
                                      Chip(label: Text(module.toUpperCase())),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kullanım İstatistikleri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (usage.isEmpty)
                          const Text('Henüz kullanım verisi bulunmuyor.')
                        else
                          ...usage.entries.map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.key.toUpperCase()),
                              trailing: Text(entry.value.toString()),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openCompanyPanel(context, projectId),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Şirket Panelini Aç'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: active
                          ? () async {
                              await CompanyService.instance.deactivateCompany(
                                companyId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Şirket pasif edildi'),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('Pasif Et'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm =
                            await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Şirketi Sil'),
                                content: const Text(
                                  'Şirketi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Vazgeç'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (confirm) {
                          await CompanyService.instance.deleteCompany(
                            companyId,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Şirket silindi')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCompanyPanel(BuildContext context, String projectId) async {
    final url = Uri.parse('https://$projectId.web.app');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şirket paneli açılamadı.')),
        );
      }
    }
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}
