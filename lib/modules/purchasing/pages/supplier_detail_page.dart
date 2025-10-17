import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/supplier_model.dart';
import '../services/supplier_service.dart';
import 'supplier_edit_page.dart';

class SupplierDetailPage extends StatelessWidget {
  const SupplierDetailPage({super.key, required this.supplierId});

  final String supplierId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedarikçi Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: StreamBuilder<SupplierModel?>(
        stream: SupplierService.instance.watchSupplier(supplierId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tedarikçi bilgisi yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final supplier = snapshot.data;
          if (supplier == null) {
            return const Center(
              child: Text('Tedarikçi bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _SupplierDetailContent(supplier: supplier);
        },
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final supplier = await SupplierService.instance.getSupplierById(supplierId);
    if (!context.mounted) return;

    if (supplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tedarikçi bulunamadı.')));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SupplierEditPage(supplier: supplier)),
    );
  }
}

class _SupplierDetailContent extends StatelessWidget {
  const _SupplierDetailContent({required this.supplier});

  final SupplierModel supplier;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.supplierName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Durum',
                    value: supplier.status.toUpperCase(),
                  ),
                  _DetailRow(
                    label: 'Yetkili',
                    value: supplier.contactPerson.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.contactPerson,
                  ),
                  _DetailRow(
                    label: 'E-posta',
                    value: supplier.email.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.email,
                  ),
                  _DetailRow(
                    label: 'Telefon',
                    value: supplier.phone.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.phone,
                  ),
                  _DetailRow(
                    label: 'Adres',
                    value: supplier.address.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.address,
                  ),
                  _DetailRow(
                    label: 'Şehir',
                    value: supplier.city.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.city,
                  ),
                  _DetailRow(
                    label: 'Ülke',
                    value: supplier.country.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.country,
                  ),
                  _DetailRow(
                    label: 'Vergi No',
                    value: supplier.taxNumber.isEmpty
                        ? 'Belirtilmemiş'
                        : supplier.taxNumber,
                  ),
                  _DetailRow(
                    label: 'Ödeme Koşulu',
                    value: _paymentTermLabel(supplier.paymentTerms),
                  ),
                  if (supplier.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Oluşturma: ${dateFormat.format(supplier.createdAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  if (supplier.updatedAt != null)
                    Text(
                      'Güncelleme: ${dateFormat.format(supplier.updatedAt!)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (supplier.notes ?? '').isEmpty
                        ? 'Not girilmemiş.'
                        : supplier.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentTermLabel(String value) {
    switch (value) {
      case 'net15':
        return 'Net 15';
      case 'net30':
        return 'Net 30';
      case 'advance':
        return 'Peşin';
      case 'custom':
        return 'Özel';
      default:
        return value;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
