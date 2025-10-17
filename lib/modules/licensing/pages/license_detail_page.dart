import 'package:flutter/material.dart';

import '../models/license_model.dart';
import '../services/license_service.dart';
import '../widgets/payment_history_widget.dart';
import 'license_edit_page.dart';

class LicenseDetailPageArgs {
  const LicenseDetailPageArgs({
    required this.companyId,
    required this.licenseId,
    this.companyName,
  });

  final String companyId;
  final String licenseId;
  final String? companyName;
}

class LicenseDetailPage extends StatelessWidget {
  const LicenseDetailPage({
    super.key,
    required this.companyId,
    required this.licenseId,
    this.companyName,
  });

  static const routeName = '/superadmin/licenses/detail';

  final String companyId;
  final String licenseId;
  final String? companyName;

  @override
  Widget build(BuildContext context) {
    final title = companyName != null
        ? 'Lisans Detayı • ${companyName!}'
        : 'Lisans Detayı';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<LicenseModel?>(
        stream: LicenseService.instance.watchLicense(companyId, licenseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Lisans bilgileri alınamadı: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final license = snapshot.data;
          if (license == null) {
            return const Center(child: Text('Lisans kaydı bulunamadı.'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LicenseOverview(license: license),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            LicenseEditPage.routeName,
                            arguments: LicenseEditPageArgs(
                              companyId: companyId,
                              editLicense: license,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Düzenle'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await LicenseService.instance.updateLicenseStatus(
                            companyId,
                            licenseId,
                            license.isActive ? 'suspended' : 'active',
                          );
                        },
                        icon: Icon(
                          license.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        label: Text(
                          license.isActive ? 'Askıya Al' : 'Aktifleştir',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await LicenseService.instance.updateLicenseStatus(
                            companyId,
                            licenseId,
                            'expired',
                          );
                        },
                        icon: const Icon(Icons.lock_clock_outlined),
                        label: const Text('Süresi Doldu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Ödeme Geçmişi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PaymentHistoryWidget(
                    companyId: companyId,
                    licenseId: licenseId,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LicenseOverview extends StatelessWidget {
  const _LicenseOverview({required this.license});

  final LicenseModel license;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _format(license.startDate);
    final end = _format(license.endDate);
    final modules = license.modules.isEmpty
        ? '-'
        : license.modules.map((m) => m.toUpperCase()).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  modules,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(label: Text(license.status.toUpperCase())),
            ],
          ),
          const SizedBox(height: 12),
          Text('Başlangıç: $start'),
          Text('Bitiş: $end'),
          Text(
            'Fiyat: ${license.price.toStringAsFixed(2)} ${license.currency}',
          ),
          Text('Kalan Gün: ${license.remainingDays ?? '-'}'),
          const SizedBox(height: 12),
          Text(
            'Oluşturulma: ${_format(license.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Güncellenme: ${_format(license.updatedAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _format(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
