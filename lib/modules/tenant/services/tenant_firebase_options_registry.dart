import 'package:firebase_core/firebase_core.dart';

import 'package:atgevosystem/config/firebase_options_atgmakina.dart'
    as atg_makina_options;
import 'package:atgevosystem/firebase_options.dart' as default_options;
import 'package:atgevosystem/firebase_options_demo.dart' as demo_options;

/// Tenant bazlı FirebaseOptions çözücüsü.
///
/// Yeni firma projeleri için `lib/config/firebase_options_<firma>.dart`
/// dosyaları oluşturulmalı ve bu kayıt sınıfına eklenmelidir.
class TenantFirebaseOptionsRegistry {
  TenantFirebaseOptionsRegistry._();

  static final TenantFirebaseOptionsRegistry instance =
      TenantFirebaseOptionsRegistry._();

  final Map<String, FirebaseOptions Function()> _projectResolvers =
      <String, FirebaseOptions Function()>{
        'atgevosystem': () =>
            default_options.DefaultFirebaseOptions.currentPlatform,
        'atgevo-atgmakina': () =>
            atg_makina_options.AtgMakinaFirebaseOptions.currentPlatform,
        'atgevo-demo': () =>
            demo_options.DefaultFirebaseOptions.currentPlatform,
      };

  /// Belirtilen `firebaseProjectId` için uygun [FirebaseOptions] döndürür.
  ///
  /// Kayıtlı olmayan projeler için `null` döner.
  FirebaseOptions? resolveByProjectId(String? firebaseProjectId) {
    if (firebaseProjectId == null || firebaseProjectId.isEmpty) {
      return null;
    }
    final resolver = _projectResolvers[firebaseProjectId];
    return resolver?.call();
  }

  /// Yeni bir proje tanımlayıcısı için dinamik çözümleyici ekler.
  void registerProject(
    String firebaseProjectId,
    FirebaseOptions Function() resolver,
  ) {
    _projectResolvers[firebaseProjectId] = resolver;
  }
}
