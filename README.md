# Crimson HUD — watch face futuristik merah-oranye untuk Garmin Venu Sq 2

Watch face Connect IQ (Monkey C) untuk `venusq2` dan `venusq2m` (AMOLED 320×360). Semua elemen digambar
secara prosedural dengan `Toybox.Graphics` — tanpa bitmap selain ikon launcher.

## Tata letak
| Area | Y (px) | Isi |
|---|---|---|
| Bingkai | tepi 16 px | Bracket sudut bersudut potong (crimson) + grid horizontal tipis di belakang jam |
| Header | 22–55 | Bluetooth + notifikasi · tanggal `WED 18 NOV` · baterai 5 segmen + persen |
| Jam | 85–195 | Jam amber + garis bawah neon, menit oranye neon, halo crimson gelap, kotak detik |
| Langkah | 205–255 | Bar equalizer 24 segmen, gradasi crimson → oranye, persentase target |
| Telemetri | 265–335 | Detak jantung (BPM) · langkah · kalori, dipisah garis vertikal |

**Always-on / sleep**: hanya jam redup + bar baterai tipis 2 px, bergeser setiap menit pada grid 5×5
(perlindungan burn-in AMOLED). Grid, bingkai, halo, dan detik disembunyikan.

## Struktur
```
manifest.xml
monkey.jungle
resources/strings/strings.xml
resources/drawables/drawables.xml
resources/drawables/launcher_icon.svg
source/FuturisticRedOrangeApp.mc     entry point (AppBase)
source/FuturisticRedOrangeView.mc    WatchFace: layout, data sensor, sleep state
source/HudRenderer.mc                palet warna + helper gambar (bracket, bar segmen, ikon)
```

## Build dengan Monkey C SDK
1. Install [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/), unduh SDK terbaru dan
   device **Venu Sq 2** / **Venu Sq 2 Music**.
2. Buat developer key (sekali saja):
   ```bash
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
3. Compile:
   ```bash
   monkeyc -f monkey.jungle -d venusq2 -o bin/CrimsonHud.prg -y developer_key.der
   ```

## Build di GitHub Codespaces / Linux (tanpa .exe)
Cocok bila laptop tidak boleh menjalankan `.exe`. Buka repo di Codespaces, lalu di terminal:
```bash
bash scripts/ciq-setup.sh
```
Sekali saja: memasang Java dan `connect-iq-sdk-manager-cli` (open-source, tidak resmi), menampilkan perjanjian lisensi
Garmin, meminta email + password Garmin (diketik tersembunyi, tidak disimpan oleh skrip), mengunduh SDK serta
device `venusq2`/`venusq2m`, dan membuat developer key. Akun dengan verifikasi dua langkah (MFA) kemungkinan gagal login.

Setelah itu, setiap kali ingin compile:
```bash
bash scripts/build.sh
```
Hasilnya `bin/CrimsonHud.prg`. Unduh lewat panel Explorer (klik kanan → Download), lalu salin ke `GARMIN/APPS/` di jam.
Simulator tidak tersedia di Codespaces (tanpa layar).

## Menjalankan di simulator
```bash
connectiq &
monkeydo bin/CrimsonHud.prg venusq2
```
Di simulator: **Settings → Low Power Mode** untuk menguji tampilan always-on, dan
**Simulation → Activity Data** untuk mengisi langkah/detak jantung.

VS Code: pasang ekstensi *Monkey C*, lalu *Monkey C: Build for Device* atau tekan F5.

## Pasang ke jam
Sambungkan jam via USB dan salin `bin/CrimsonHud.prg` ke folder `GARMIN/APPS/`.

## Catatan
- Kalori yang ditampilkan adalah **total kalori harian** (`ActivityMonitor.Info.calories`); Connect IQ tidak
  menyediakan kalori aktif secara langsung.
- Efek "glow" dibuat dari salinan teks berwarna gelap yang digeser, karena Connect IQ tidak punya blur.
