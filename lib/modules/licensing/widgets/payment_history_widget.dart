import 'package:flutter/material.dart';

import '../models/payment_record_model.dart';
import '../services/payment_gateway_service.dart';

class PaymentHistoryWidget extends StatelessWidget {
  const PaymentHistoryWidget({
    super.key,
    required this.companyId,
    required this.licenseId,
  });

  final String companyId;
  final String licenseId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentRecordModel>>(
      stream: PaymentGatewayService.instance.getPaymentHistory(
        companyId,
        licenseId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ödemeler yüklenemedi: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? const <PaymentRecordModel>[];
        if (payments.isEmpty) {
          return const Center(
            child: Text('Bu lisans için ödeme kaydı bulunmuyor.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          separatorBuilder: (context, _) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final payment = payments[index];
            final method = payment.method.toUpperCase();
            final amount =
                '${payment.amount.toStringAsFixed(2)} ${payment.currency}';
            final date = payment.paymentDate != null
                ? '${payment.paymentDate!.day.toString().padLeft(2, '0')}.'
                      '${payment.paymentDate!.month.toString().padLeft(2, '0')}.'
                      '${payment.paymentDate!.year}'
                : '-';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Ödeme $amount'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yöntem: $method'),
                  Text('Tarih: $date'),
                  if (payment.transactionId.isNotEmpty)
                    Text('İşlem No: ${payment.transactionId}'),
                  if (payment.notes?.isNotEmpty == true)
                    Text('Not: ${payment.notes}'),
                ],
              ),
              trailing: Chip(label: Text(payment.status.toUpperCase())),
            );
          },
        );
      },
    );
  }
}
