# QA Panel Kullanımı

1. CI/GitHub Actions pipeline'ı `ingestQaRun` callable fonksiyonunu çağırarak test sonuçlarını paylaşır.
2. Yönetici kullanıcılar uygulamada `Test & QA` menüsünden son çalışmaları, kapsam trendini ve başarısız testleri görebilir.
3. Yerel geliştirme için `flutter test --coverage` çalıştırdıktan sonra `lcov.info` dosyasını “Yerel Test Yükle” butonuyla yükleyip gerekli test sayıları girerek kayıt oluşturabilirsiniz.
