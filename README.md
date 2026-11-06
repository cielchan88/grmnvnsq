# Venu Sq Face — watch face untuk Garmin Venu Sq 2

Watch face digital (Connect IQ / Monkey C) untuk layar AMOLED 320×360 Venu Sq 2 dan Venu Sq 2 Music.

## Tampilan
- **Baris status**: indikator koneksi ponsel + jumlah notifikasi (kiri), baterai + persen (kanan)
- **Tanggal**: format bahasa perangkat, mis. `JUM, 6 NOV`
- **Jam besar**: jam putih, menit biru; ikut pengaturan 12/24 jam
- **Bar progres langkah** terhadap target harian (hijau bila tercapai)
- **Statistik**: langkah, detak jantung, kalori
- **Always-on (AOD)**: jam redup kecil yang bergeser tiap menit (perlindungan burn-in AMOLED)

## Build
1. Install [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) dan device `venusq2` lewat SDK Manager.
2. Buat developer key (sekali saja):
   ```bash
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
3. Compile:
   ```bash
   monkeyc -f monkey.jungle -d venusq2 -o bin/VenuSqFace.prg -y developer_key.der
   ```
4. Jalankan di simulator: `connectiq` lalu `monkeydo bin/VenuSqFace.prg venusq2`.
5. Pasang ke jam: sambungkan USB, salin `bin/VenuSqFace.prg` ke folder `GARMIN/APPS/`.

Atau pakai VS Code + ekstensi Monkey C: *Monkey C: Build for Device*.
