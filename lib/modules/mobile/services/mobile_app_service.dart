/// MobileAppService, PWA ve beklenen mobil uygulama fonksiyonları için
/// ortak erişim noktasını temsil eder.
class MobileAppService {
  MobileAppService._();

  static final MobileAppService instance = MobileAppService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // PWA kurulum kontrolleri ve senkronizasyon mantığı burada kademeli olarak
    // genişletilecek. Şimdilik yalnızca tek seferlik kurulum akışını güvence altına alıyoruz.
    _initialized = true;
  }
}
