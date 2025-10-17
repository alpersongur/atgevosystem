import 'package:cloud_firestore/cloud_firestore.dart';

import '../../inventory/services/inventory_service.dart';
import '../models/grn_model.dart';
import 'purchase_order_service.dart';

class GRNService {
  GRNService._(this._firestore);

  factory GRNService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return GRNService._(firestore);
  }

  static final GRNService instance = GRNService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('grn');

  Future<String> addGRN(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();

    final docRef = await _collection.add(payload);
    final grnId = docRef.id;

    final lines = (data['lines'] as List<dynamic>? ?? const [])
        .map((line) => GRNLine.fromMap(Map<String, dynamic>.from(line)))
        .toList(growable: false);

    for (final line in lines) {
      if (line.sku.isEmpty) continue;
      final qty = line.receivedQty.round();
      if (qty <= 0) continue;
      try {
        await InventoryService.instance.adjustStock(line.sku, qty, 'increase');
      } catch (error) {
        // Stok güncellemesi başarısız olsa bile işlem devam etsin, kullanıcıya log
        // ekranda geri bildirim verilmesi çağıran katmana bırakılır.
      }
    }

    final poId = (data['po_id'] as String?)?.trim();
    if (poId != null && poId.isNotEmpty) {
      await _syncPOStatus(poId);
    }

    return grnId;
  }

  Stream<List<GRNModel>> getGRNs() {
    return _collection
        .orderBy('received_date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(GRNModel.fromFirestore).toList(growable: false),
        );
  }

  Stream<GRNModel?> watchGRN(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return GRNModel.fromFirestore(snapshot);
    });
  }

  Future<GRNModel?> getGRNById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return GRNModel.fromFirestore(doc);
  }

  Future<List<GRNModel>> getGRNsByPO(String poId) async {
    final snapshot = await _collection.where('po_id', isEqualTo: poId).get();
    return snapshot.docs.map(GRNModel.fromFirestore).toList(growable: false);
  }

  Future<void> _syncPOStatus(String poId) async {
    final po = await PurchaseOrderService.instance.getPOById(poId);
    if (po == null) return;

    final grnList = await getGRNsByPO(poId);
    final receivedMap = <String, double>{};

    for (final grn in grnList) {
      final lines = grn.lines;
      for (final line in lines) {
        receivedMap[line.sku] = (receivedMap[line.sku] ?? 0) + line.receivedQty;
      }
    }

    String newStatus = po.status;
    var fullyReceived = true;
    var anyReceived = false;

    for (final line in po.lines) {
      final orderedQty = line.quantity;
      final receivedQty = receivedMap[line.sku] ?? 0;
      if (receivedQty >= orderedQty && orderedQty > 0) {
        anyReceived = true;
        continue;
      }
      if (receivedQty > 0) {
        anyReceived = true;
        fullyReceived = false;
      } else {
        fullyReceived = false;
      }
    }

    if (fullyReceived && po.lines.isNotEmpty) {
      newStatus = 'received';
    } else if (anyReceived) {
      newStatus = 'partially_received';
    } else {
      newStatus = 'open';
    }

    if (newStatus != po.status) {
      await PurchaseOrderService.instance.updateStatus(poId, newStatus);
    }
  }
}
