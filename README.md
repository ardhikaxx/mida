# MIDA — Mobile ICD Database Application

<div align="center">
  <img src="assets/images/logo-kemkes-new.png" alt="Logo Kemenkes" width="120"/>
  <br/><br/>
  <p><strong>Aplikasi offline referensi kode ICD untuk tenaga kesehatan, koder, dan mahasiswa kedokteran Indonesia</strong></p>
  <p>
    <img src="assets/images/logo-kemenkes.png" alt="Kemenkes" width="80"/>
    <img src="assets/images/bangga-melayani-bangsa-seeklogo.png" alt="Bangga Melayani Bangsa" width="80"/>
    <img src="assets/images/logo-berakhlak.png" alt="Berakhlak" width="80"/>
  </p>
</div>

## Fitur

| Fitur | Deskripsi |
|---|---|
| **🔍 Pencarian Cepat** | Cari kode berdasarkan kode, deskripsi, atau chapter dengan debounce + autocomplete |
| **📊 5 Klasifikasi ICD** | ICD-10 (18.543 kode), ICD-MM, ICD-PM, ICD-O, ICD-9-CM |
| **📂 Hierarki Kode** | Lihat struktur chapter → kategori → subkategori |
| **📋 Detail Lengkap** | Hero gradient, informasi chapter, kode serupa, salin kode |
| **🌳 Pohon ICD** | Jelajahi kode secara hierarkis (huruf → prefix → kode) |
| **🩺 Diagnosis → ICD** | Ketik diagnosis, dapatkan rekomendasi kode real-time |
| **🤒 Cari Gejala** | Cari kode berdasarkan gejala dengan pemetaan ID→EN |
| **📖 Glosarium Medis** | Kamus istilah medis offline bahasa Indonesia |
| **✅ Validasi Kode** | Periksa format dan ketersediaan kode di database |
| **📘 Panduan Pengkodean** | Aturan dan panduan pengkodean per klasifikasi |
| **🔗 Salin Kode** | Tap badge kode untuk menyalin ke clipboard |
| **🏷️ Filter Chapter** | Filter kode berdasarkan chapter dan bagian tubuh |
| **📱 Onboarding** | Panduan pengenalan aplikasi (hanya sekali) |
| **🌐 Offline** | Semua data disimpan lokal, tidak perlu koneksi internet |

## Klasifikasi

| Klasifikasi | Jumlah Kode | Keterangan |
|---|---|---|
| **ICD-10** | 18.543 | International Classification of Diseases, 10th Revision |
| **ICD-MM** | 4.777 | Maternal Mortality |
| **ICD-PM** | 838 | Perinatal Mortality |
| **ICD-O** | 4.217 | Oncology (Topografi + Morfologi) |
| **ICD-9-CM** | 4.626 | Clinical Modification |

**Total: ~33.000 kode ICD**

## Tech Stack

- **Framework:** Flutter 3.x (Dart ^3.11)
- **Material Design 3** dengan seed color teal (`#00796B`)
- **Penyimpanan:** SharedPreferences (onboarding flag)
- **Data:** JSON bundling (offline-first)
- **Ikon:** Cupertino Icons

## Struktur Project

```
mida/
├── assets/
│   ├── icd10.json          # ICD-10
│   ├── icd_9cm.json        # ICD-9-CM
│   ├── icd_mm.json         # ICD-MM
│   ├── icd_pm.json         # ICD-PM
│   ├── icd_o.json          # ICD-O
│   ├── data/               # CSV sumber (tidak di-runtime)
│   └── images/             # Logo & QRIS
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── icd_code.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── home_screen.dart
│   │   ├── search_screen.dart
│   │   ├── detail_screen.dart
│   │   ├── about_screen.dart
│   │   ├── diagnosis_screen.dart
│   │   ├── icd_tree_screen.dart
│   │   ├── medical_dict_screen.dart
│   │   ├── generator_screen.dart
│   │   ├── code_validator_screen.dart
│   │   └── coding_guidelines_screen.dart
│   └── services/
│       └── icd_service.dart
├── pubspec.yaml
└── README.md
```

## Cara Menjalankan

```bash
# Clone repositori
git clone https://github.com/ardhikaxx/mida.git
cd mida

# Install dependencies
flutter pub get

# Jalankan (debug)
flutter run

# Build APK
flutter build apk --release
```

## Persyaratan

- Flutter SDK ^3.11
- Dart ^3.11
- Android SDK / Xcode (untuk build)

## Data

Data kode ICD bersumber dari data publik e-klaim Indonesia. Seluruh data disimpan dalam format JSON dan di-bundle langsung ke dalam aplikasi — tidak memerlukan koneksi internet sama sekali.

## Pengembang

**Yanuar Ardhika Rahmadhani Ubaidillah**

Dibangun untuk memudahkan tenaga kesehatan Indonesia dalam mengakses referensi kode ICD secara cepat dan offline.

---

<p align="center">
  <img src="assets/images/qris.png" alt="QRIS" width="150"/>
  <br/>
  <em>Dukung pengembangan dengan donasi via QRIS</em>
</p>
