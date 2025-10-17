import 'package:flutter/material.dart';

class ReportFiltersWidget extends StatefulWidget {
  const ReportFiltersWidget({
    super.key,
    required this.onChanged,
    required this.initialFrom,
    required this.initialTo,
  });

  final ValueChanged<ReportFilterResult> onChanged;
  final DateTime initialFrom;
  final DateTime initialTo;

  @override
  State<ReportFiltersWidget> createState() => _ReportFiltersWidgetState();
}

class _ReportFiltersWidgetState extends State<ReportFiltersWidget> {
  late DateTime _from;
  late DateTime _to;
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_currentFilters());
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) {
          _to = _from;
        }
      } else {
        _to = picked;
        if (_from.isAfter(_to)) {
          _from = _to;
        }
      }
      widget.onChanged(_currentFilters());
    });
  }

  ReportFilterResult _currentFilters() {
    return ReportFilterResult(
      from: _from,
      to: _to,
      extra: {
        if (_customerController.text.isNotEmpty)
          'customerId': _customerController.text,
        if (_supplierController.text.isNotEmpty)
          'supplierId': _supplierController.text,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtreler',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Başlangıç',
                    value: _from,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Bitiş',
                    value: _to,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'Müşteri ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => widget.onChanged(_currentFilters()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Tedarikçi ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => widget.onChanged(_currentFilters()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

class ReportFilterResult {
  const ReportFilterResult({
    required this.from,
    required this.to,
    required this.extra,
  });

  final DateTime from;
  final DateTime to;
  final Map<String, dynamic> extra;
}
