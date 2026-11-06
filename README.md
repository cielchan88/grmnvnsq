# Venu Sq HUD — watch face untuk Garmin Venu Sq 2

Watch face digital (Connect IQ / Monkey C) untuk layar AMOLED 320×360 Venu Sq 2 dan Venu Sq 2 Music.

## Tampilan (gaya HUD futuristik, label bahasa Inggris)
- **Baris status**: ikon diamond koneksi ponsel + jumlah notifikasi (kiri), baterai 5 segmen + persen (kanan)
- **Tanggal**: selalu bahasa Inggris, mis. `FRI  06 NOV`, diapit garis HUD
- **Jam besar** di dalam bracket sudut: jam putih, menit cyan, bayangan offset; label `24H`/`AM`/`PM` dan detik
- **Bar langkah 24 segmen** terhadap target harian (hijau neon bila tercapai)
- **Panel statistik bersudut potong**: STEPS, BPM, KCAL
- **Always-on (AOD)**: jam redup + bracket kecil yang bergeser tiap menit (perlindungan burn-in AMOLED)

## Build
1. Install [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) dan device `venusq2` lewat SDK Manager.
2. Buat developer key (sekali saja):
   ```bash
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
3. Compile:
   ```bash
   monkeyc -f monkey.jungle -d venusq2 -o bin/VenuSqHud.prg -y developer_key.der
   ```
4. Jalankan di simulator: `connectiq` lalu `monkeydo bin/VenuSqHud.prg venusq2`.
5. Pasang ke jam: sambungkan USB, salin `bin/VenuSqHud.prg` ke folder `GARMIN/APPS/`.

Atau pakai VS Code + ekstensi Monkey C: *Monkey C: Build for Device*.
