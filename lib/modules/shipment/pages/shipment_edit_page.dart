import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../crm/models/customer_model.dart';
import '../../crm/services/customer_service.dart';
import '../../production/models/production_order_model.dart';
import '../../production/services/production_service.dart';
import '../services/shipment_service.dart';
import '../../inventory/services/inventory_service.dart';

class ShipmentEditPage extends StatefulWidget {
  const ShipmentEditPage({super.key, this.shipmentId, this.initialOrderId});

  static const routeName = '/shipment/add';

  final String? shipmentId;
  final String? initialOrderId;

  bool get isEditing => shipmentId != null;

  @override
  State<ShipmentEditPage> createState() => _ShipmentEditPageState();
}

class _ShipmentEditPageState extends State<ShipmentEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _shipmentNoController = TextEditingController();
  final _carrierController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _departureDateController = TextEditingController();

  DateTime? _departureDate;
  String? _selectedOrderId;
  String? _selectedCustomerId;
  String? _inventoryItemId;
  String _status = 'preparing';

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadShipment();
    }
  }

  @override
  void dispose() {
    _shipmentNoController.dispose();
    _carrierController.dispose();
    _vehiclePlateController.dispose();
    _driverNameController.dispose();
    _notesController.dispose();
    _departureDateController.dispose();
    super.dispose();
  }

  Future<void> _loadShipment() async {
    setState(() => _isLoading = true);
    try {
      final shipment = await ShipmentService.instance.getShipmentById(
        widget.shipmentId!,
      );
      if (!mounted) return;
      if (shipment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sevkiyat kaydı bulunamadı.')),
        );
        Navigator.of(context).pop();
        return;
      }

      _shipmentNoController.text = shipment.shipmentNo;
      _carrierController.text = shipment.carrier;
      _vehiclePlateController.text = shipment.vehiclePlate;
      _driverNameController.text = shipment.driverName;
      _notesController.text = shipment.notes ?? '';
      _selectedOrderId = shipment.productionOrderId;
      _selectedCustomerId = shipment.customerId;
      _inventoryItemId = shipment.inventoryItemId;
      _status = shipment.status;
      if (shipment.departureDate != null) {
        _departureDate = shipment.departureDate;
        _departureDateController.text = DateFormat(
          'dd.MM.yyyy',
        ).format(shipment.departureDate!);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sevkiyat yüklenemedi: $error')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
        _departureDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedOrderId == null || _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen üretim talimatı ve müşteri seçin.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'production_order_id': _selectedOrderId,
      'customer_id': _selectedCustomerId,
      'inventory_item_id': _inventoryItemId,
      'shipment_no': _shipmentNoController.text.trim(),
      'carrier': _carrierController.text.trim(),
      'vehicle_plate': _vehiclePlateController.text.trim(),
      'driver_name': _driverNameController.text.trim(),
      'status': _status,
      'departure_date': _departureDate,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await ShipmentService.instance.updateShipment(
          widget.shipmentId!,
          payload,
        );
      } else {
        await ShipmentService.instance.addShipment(payload);
        if (_inventoryItemId != null && _status == 'delivered') {
          await InventoryService.instance.adjustStock(
            _inventoryItemId!,
            1,
            'decrease',
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Sevkiyat güncellendi.'
                : 'Sevkiyat oluşturuldu.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt başarısız: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _prefillFromOrder(ProductionOrderModel? order) {
    if (order == null) return;
    _selectedCustomerId = order.customerId;
    _inventoryItemId = order.inventoryItemId;
    if (_shipmentNoController.text.isEmpty) {
      final now = DateTime.now();
      _shipmentNoController.text =
          'SHP-${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    }
    setState(() {}); // refresh dropdowns
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Sevkiyatı Düzenle' : 'Sevkiyat Oluştur',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ProductionOrderModel>>(
              stream: ProductionService.instance.getOrdersStream().map(
                (orders) => orders
                    .where((order) => order.status == 'completed')
                    .toList(),
              ),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = orderSnapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sevkiyat oluşturmak için tamamlanmış bir üretim talimatı bulunmuyor.',
                      ),
                    ),
                  );
                }

                _selectedOrderId ??= widget.initialOrderId ?? orders.first.id;
                _prefillFromOrder(
                  orders.firstWhere(
                    (order) => order.id == _selectedOrderId,
                    orElse: () => orders.first,
                  ),
                );

                return StreamBuilder<List<CustomerModel>>(
                  stream: CustomerService.instance.getCustomers(),
                  builder: (context, customerSnapshot) {
                    final customers = {
                      for (final customer in customerSnapshot.data ?? [])
                        customer.id: customer.companyName,
                    };

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey('order-${_selectedOrderId ?? ''}'),
                              initialValue: _selectedOrderId,
                              decoration: const InputDecoration(
                                labelText: 'Üretim Talimatı',
                              ),
                              items: orders
                                  .map<DropdownMenuItem<String>>(
                                    (order) => DropdownMenuItem<String>(
                                      value: order.id,
                                      child: Text(order.quoteId),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedOrderId = value);
                                final selectedOrder = orders.firstWhere(
                                  (order) => order.id == value,
                                  orElse: () => orders.first,
                                );
                                _prefillFromOrder(selectedOrder);
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                'customer-${_selectedCustomerId ?? ''}',
                              ),
                              initialValue: _selectedCustomerId,
                              decoration: const InputDecoration(
                                labelText: 'Müşteri',
                              ),
                              items: customers.entries
                                  .map<DropdownMenuItem<String>>(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCustomerId = value),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _shipmentNoController,
                              decoration: const InputDecoration(
                                labelText: 'Sevkiyat No',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Sevkiyat numarası zorunludur';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _carrierController,
                              decoration: const InputDecoration(
                                labelText: 'Taşıyıcı',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _vehiclePlateController,
                              decoration: const InputDecoration(
                                labelText: 'Araç Plakası',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _driverNameController,
                              decoration: const InputDecoration(
                                labelText: 'Sürücü Adı',
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Durum',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'preparing',
                                  child: Text('Hazırlanıyor'),
                                ),
                                DropdownMenuItem(
                                  value: 'on_the_way',
                                  child: Text('Yolda'),
                                ),
                                DropdownMenuItem(
                                  value: 'delivered',
                                  child: Text('Teslim Edildi'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _departureDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Çıkış Tarihi',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.date_range_outlined),
                                  onPressed: _pickDepartureDate,
                                ),
                              ),
                              onTap: _pickDepartureDate,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notlar',
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isSaving ? null : _submit,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Kaydet'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
