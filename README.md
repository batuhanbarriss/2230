# Our Space - Çiftlere Özel Flutter Uygulaması ❤️

Supabase Realtime ve Storage ile güçlendirilmiş, çiftlere özel minimalist ve modern mobil uygulama.

---

## 🌟 Dahil Edilen Özellikler

1. **Güvenlik & PIN Kilidi:**
   - Uygulama açılışında 4 haneli PIN sorgusu.
   - Ayarlar menüsünden PIN belirleme, değiştirme veya kapatabilme.

2. **Birliktelik & Yıldönümü Sayacı:**
   - Birlikte geçen gün sayısı sayacı (`X Gündür Birlikteyiz ❤️`).
   - Bir sonraki yıldönümüne kalan gün göstergesi.
   - Birliktelik başlangıç tarihini takvimden seçebilme.

3. **Bizim Hikayemiz (Anılar & Fotoğraflar):**
   - Galeriden anı ve fotoğraf yükleme.
   - Fotoğrafa dokunulduğunda tam ekran görüntüleme ve tutamla yakınlaştırma (**Pinch-to-Zoom**).
   - Hem veritabanından hem de Supabase Storage'dan fotoğrafı güvenli silme.

4. **Özel Sohbet (Canlı Mesajlaşma):**
   - Anlık (Realtime) mesajlaşma.
   - Mesaj saatleri (`HH:mm`) ve gönderen bilgisi.
   - Otomatik aşağı kaydırma (auto-scroll).
   - Kendi mesajlarınıza basılı tutarak silebilme.

5. **Ortak Planlar & Dilekler:**
   - Birlikte yapılacaklar listesi (To-Do).
   - Tamamlanan planları işaretleme (üstü çizili).
   - Tamamlanan plan sayacı ve silme desteği.

6. **Kullanıcı & Profil Yönetimi:**
   - Ayarlar menüsünden her cihaz için isim belirleme (örn: Batuhan / Sevgilim).
   - Cihaz bazlı hafıza (kod değiştirmeden iki cihazda farklı isim kullanabilme).

---

## 🚀 Kurulum Adımları

### 1. Supabase Projenizi Hazırlayın
1. [supabase.com](https://supabase.com) üzerinde yeni bir proje oluşturun.
2. Sol menüdeki **SQL Editor** alanına gidin ve projedeki `supabase_schema.sql` dosyasının içeriğini yapıştırıp **Run** deyin.
3. Sol menüdeki **Storage** alanına gidin:
   - **`photos`** adında bir bucket oluşturun.
   - **Public bucket** seçeneğini açık (Enabled) yapın.
4. **Project Settings > API** bölümünden:
   - `Project URL`
   - `Project API Keys` altındaki `anon / public` anahtarı alın.
5. `lib/main.dart` içerisindeki `supabaseUrl` ve `supabaseAnonKey` alanlarına yapıştırın.

---

### 2. İzinler

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Bizim anılarımızı seçmek için galeri iznine ihtiyacımız var.</string>
<key>NSCameraUsageDescription</key>
<string>Yeni anı fotoğrafı çekmek için kamera izni gerekiyor.</string>
```

---

### 3. Çalıştırma
```bash
flutter pub get
flutter run
```
