import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../tenant/models/tenant_model.dart';
import '../models/license_model.dart';
import '../services/license_service.dart';
import 'license_list_page.dart';

class LicenseManagementPage extends StatelessWidget {
  const LicenseManagementPage({super.key});

  static const routeName = '/superadmin/licenses/management';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lisans Yönetimi')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('companies').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Firmalar yüklenemedi: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (docs.isEmpty) {
            return const Center(child: Text('Kayıtlı firma bulunamadı.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final company = TenantModel(
                id: doc.id,
                companyName:
                    (data['company_name'] as String? ??
                            data['name'] as String? ??
                            '')
                        .trim(),
                firebaseProjectId:
                    (data['firebase_project_id'] as String? ??
                            data['projectId'] as String? ??
                            '')
                        .trim(),
                ownerEmail:
                    (data['owner_email'] as String? ??
                            data['email'] as String? ??
                            '')
                        .trim(),
                modules: List<String>.from(
                  data['modules'] as List? ?? const [],
                ),
                status:
                    (data['status'] as String? ??
                            (data['active'] != false ? 'active' : 'inactive'))
                        .toLowerCase(),
                createdAt: _toDate(data['created_at']),
                updatedAt: _toDate(data['updated_at']),
              );

              return _CompanyLicenseCard(company: company);
            },
          );
        },
      ),
    );
  }
}

class _CompanyLicenseCard extends StatelessWidget {
  const _CompanyLicenseCard({required this.company});

  final TenantModel company;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseModel?>(
      future: LicenseService.instance.fetchActiveLicense(company.id),
      builder: (context, snapshot) {
        final license = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        company.companyName.isEmpty
                            ? 'Adsız Firma'
                            : company.companyName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Chip(label: Text(company.status.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const LinearProgressIndicator(minHeight: 2)
                else if (license == null)
                  const Text('Aktif lisans bulunamadı.')
                else ...[
                  Text(
                    'Dönem: ${_formatDate(license.startDate)} - ${_formatDate(license.endDate)}',
                  ),
                  Text('Kalan Gün: ${license.remainingDays ?? '-'}'),
                  Text(
                    'Modüller: ${license.modules.map((m) => m.toUpperCase()).join(', ')}',
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        LicenseListPage.routeName,
                        arguments: LicenseListPageArgs(
                          companyId: company.id,
                          companyName: company.companyName,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Yenile / Yönet'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}

DateTime? _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
