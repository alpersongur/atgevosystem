import 'package:firebase_core/firebase_core.dart';

import 'package:atgevosystem/firebase_options.dart' as base;

/// ATG Makina firmasına ait Firebase seçeneklerini temsil eder.
///
/// Not: Gerçek projeye ait değerler henüz FlutterFire CLI ile
/// üretilmemişse, bu dosyadaki getter varsayılan uygulama ayarlarına
/// yönlendirilmiştir. Firma için ayrı bir Firebase projesi oluşturulduğunda
/// FlutterFire CLI sonucunda gelen değerler buraya taşınmalıdır.
class AtgMakinaFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      base.DefaultFirebaseOptions.currentPlatform;
}
