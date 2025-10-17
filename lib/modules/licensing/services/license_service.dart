import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/timestamp_helper.dart';
import '../../tenant/services/tenant_service.dart';
import '../models/license_model.dart';

class LicenseService with FirestoreTimestamps {
  LicenseService._();

  static final LicenseService instance = LicenseService._();

  FirebaseFirestore get _firestore => TenantService.instance.firestore;

  CollectionReference<Map<String, dynamic>> _licensesCollection(
    String companyId,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('licenses');
  }

  DocumentReference<Map<String, dynamic>> _licenseDoc(
    String companyId,
    String licenseId,
  ) {
    return _licensesCollection(companyId).doc(licenseId);
  }

  Stream<List<LicenseModel>> getLicenses(String companyId) {
    return _licensesCollection(companyId)
        .orderBy('start_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(LicenseModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  Future<String> addLicense(String companyId, Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(data);
    final ref = await _licensesCollection(companyId).add(payload);
    return ref.id;
  }

  Future<void> updateLicenseStatus(
    String companyId,
    String licenseId,
    String status,
  ) {
    final payload = withUpdateTimestamp({'status': status});
    return _licenseDoc(companyId, licenseId).update(payload);
  }

  Future<void> updateLicense(
    String companyId,
    String licenseId,
    Map<String, dynamic> data,
  ) {
    final payload = withUpdateTimestamp(data);
    return _licenseDoc(companyId, licenseId).update(payload);
  }

  Future<bool> checkLicenseValidity(String companyId) async {
    final now = DateTime.now();
    final query = await _licensesCollection(companyId)
        .where('status', isEqualTo: 'active')
        .where('end_date', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('end_date', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return false;

    final license = LicenseModel.fromSnapshot(query.docs.first);
    return license.endDate != null && license.endDate!.isAfter(now);
  }

  Future<LicenseModel?> fetchActiveLicense(String companyId) async {
    final now = DateTime.now();
    final snapshot = await _licensesCollection(companyId)
        .where('status', whereIn: ['active', 'pending'])
        .orderBy('end_date', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final license = LicenseModel.fromSnapshot(snapshot.docs.first);
    if (license.endDate == null) return license;
    if (license.endDate!.isBefore(now)) return null;
    return license;
  }

  Future<LicenseModel?> fetchLatestLicense(String companyId) async {
    final snapshot = await _licensesCollection(
      companyId,
    ).orderBy('end_date', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return LicenseModel.fromSnapshot(snapshot.docs.first);
  }

  Future<void> expireLicensesCron() async {
    final now = Timestamp.fromDate(DateTime.now());
    final companiesSnapshot = await _firestore
        .collection('companies')
        .get(const GetOptions(source: Source.server));

    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final company in companiesSnapshot.docs) {
      final companyId = company.id;
      final licensesSnapshot = await _licensesCollection(companyId)
          .where('status', isEqualTo: 'active')
          .where('end_date', isLessThan: now)
          .get(const GetOptions(source: Source.server));
      for (final licenseDoc in licensesSnapshot.docs) {
        batch.update(licenseDoc.reference, {
          'status': 'expired',
          'updated_at': FieldValue.serverTimestamp(),
        });
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<LicenseModel?> fetchLicense(String companyId, String licenseId) async {
    final doc = await _licenseDoc(companyId, licenseId).get();
    if (!doc.exists) return null;
    return LicenseModel.fromSnapshot(doc);
  }

  Stream<LicenseModel?> watchLicense(String companyId, String licenseId) {
    return _licenseDoc(companyId, licenseId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return LicenseModel.fromSnapshot(snapshot);
    });
  }
}
