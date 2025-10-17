import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import 'customer_edit_page.dart';
import '../../../services/auth_service.dart';

class CustomerDetailPage extends StatelessWidget {
  CustomerDetailPage({super.key, this.customer, String? customerId})
    : customerId = customer?.id ?? customerId,
      _customerFuture = _resolveCustomer(customer, customerId);

  static const routeName = '/crm/customers/detail';

  final CustomerModel? customer;
  final String? customerId;
  final Future<CustomerModel?> _customerFuture;

  static Future<CustomerModel?> _resolveCustomer(
    CustomerModel? customer,
    String? customerId,
  ) {
    if (customer != null) return Future.value(customer);
    if (customerId == null || customerId.isEmpty) {
      return Future.value(null);
    }
    return CustomerService().getCustomerById(customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Detayı')),
      body: FutureBuilder<CustomerModel?>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Müşteri bilgileri yüklenirken bir hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Müşteri bulunamadı.'),
              ),
            );
          }

          return _CustomerDetailContent(customer: data);
        },
      ),
    );
  }
}

class _CustomerDetailContent extends StatelessWidget {
  const _CustomerDetailContent({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final canDelete =
        AuthService.instance.currentUserRole?.toLowerCase() == 'superadmin';

    final createdAt = _formatDate(customer.createdAt);
    final updatedAt = _formatDate(customer.updatedAt);

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
                  _DetailRow(label: 'Şirket Adı', value: customer.companyName),
                  _DetailRow(
                    label: 'Yetkili Kişi',
                    value: _displayValue(customer.contactPerson),
                  ),
                  _DetailRow(
                    label: 'Email',
                    value: _displayValue(customer.email),
                  ),
                  _DetailRow(
                    label: 'Telefon',
                    value: _displayValue(customer.phone),
                  ),
                  _DetailRow(
                    label: 'Adres',
                    value: _displayValue(customer.address),
                    multiline: true,
                  ),
                  _DetailRow(
                    label: 'Şehir',
                    value: _displayValue(customer.city),
                  ),
                  _DetailRow(
                    label: 'Vergi Numarası',
                    value: _displayValue(customer.taxNumber),
                  ),
                  _DetailRow(
                    label: 'Notlar',
                    value: _displayValue(customer.notes),
                    multiline: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Oluşturulma: $createdAt',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    'Son Güncelleme: $updatedAt',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => _handleDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sil'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => CustomerEditPage(customerId: customer.id),
          ),
        )
        .then((updated) {
          if (updated == true && context.mounted) {
            Navigator.of(context).pop(true);
          }
        });
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Müşteri Sil'),
            content: Text(
              '"${customer.companyName}" kaydını silmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await CustomerService().deleteCustomer(customer.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme sırasında bir hata oluştu: $error')),
      );
    }
  }

  static String _displayValue(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? 'Belirtilmemiş' : text;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailPageArgs {
  const CustomerDetailPageArgs(this.customerId);

  final String customerId;
}
