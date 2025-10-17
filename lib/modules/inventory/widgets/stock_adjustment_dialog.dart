import 'package:flutter/material.dart';

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({super.key, required this.operation});

  final String operation; // increase or decrease

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncrease = widget.operation == 'increase';
    return AlertDialog(
      title: Text(isIncrease ? 'Stok Ekle' : 'Stok Azalt'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Miktar',
            suffixText: 'adet',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: false,
            signed: false,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Miktar gerekli';
            }
            final parsed = int.tryParse(text);
            if (parsed == null || parsed <= 0) {
              return 'Pozitif bir sayı girin';
            }
            return null;
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
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(int.parse(_amountController.text));
          },
          child: Text(isIncrease ? 'Ekle' : 'Azalt'),
        ),
      ],
    );
  }
}
