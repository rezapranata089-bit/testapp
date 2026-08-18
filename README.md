# Workout Rumah

Aplikasi personal workout companion berbasis Flutter untuk latihan di rumah.

## Menjalankan

Pastikan Flutter SDK sudah terpasang, lalu dari folder ini jalankan:

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` hanya diperlukan sekali untuk membuat folder platform Android/iOS jika belum tersedia.

## Fitur yang tersedia

- Home dengan workout hari ini
- Workout session fullscreen
- Counter repetisi, set, pause, skip, dan rest timer yang berjalan otomatis
- Halaman workout selesai
- Riwayat workout, detail riwayat, dan ringkasan statistik yang tersimpan lokal
- Grafik aktivitas mingguan
- Jadwal workout yang tersimpan lokal
- Pengaturan reminder per jadwal dan reminder global
- Edit profil lokal
- Pengaturan tema terang, gelap, dan mengikuti sistem
- Pilihan warna aksen
- Empty state dan feedback untuk alur utama

## Catatan pengembangan

Source saat ini masih memakai satu entry point agar mudah dipindahkan ke proyek Flutter
baru. Jalankan `flutter create .` sekali di folder ini untuk membuat folder Android/iOS,
lalu `flutter pub get` dan `flutter run`.

Pengiriman notifikasi sistem di background, autentikasi, serta sinkronisasi cloud adalah
lapisan berikutnya. Data inti sudah disimpan melalui `SharedPreferences` dan model jadwal
sudah menyimpan konfigurasi reminder, sehingga integrasi notifikasi dapat ditambahkan
tanpa mengubah alur UI.

## Struktur saat ini

- `lib/main.dart` — model lokal, state aplikasi, navigasi, UI, dan workout engine MVP.
- `pubspec.yaml` — dependensi Flutter dan `shared_preferences`.