# Project Planning — MITM Lab Roadmap

Status saat ini: **Phase 1 selesai** — ARP spoofing + HTTP credential sniffing berhasil.

---

## ✅ Phase 1 — MITM Dasar (SELESAI)

- [x] Topologi jaringan Host-Only + Docker macvlan
- [x] ARP spoofing dengan bettercap dari container
- [x] HTTP traffic interception (full duplex)
- [x] HTTP credential capture dari DVWA login form
- [x] Root cause analysis 9 obstacle
- [x] Dokumentasi GitHub

---

## 🔵 Phase 2 — Ekspansi Serangan (Next)

Tujuan: memperluas jenis serangan yang bisa didemonstrasikan dari posisi MITM yang sama.

### 2A — SSL Strip

Demonstrasi downgrade HTTPS ke HTTP agar traffic terenkripsi bisa dibaca.

```
Teknik: bettercap sslstrip module
Target: Juice Shop (yang support HTTPS)
Expected: credential login Juice Shop ter-capture meski user mengakses via HTTPS
```

Perintah bettercap:
```
set https.proxy.sslstrip true
https.proxy on
```

### 2B — DNS Spoofing

Redirect domain ke IP attacker — victim mengetik URL tapi diarahkan ke halaman palsu.

```
Teknik: bettercap dns.spoof module
Skenario: victim ketik "dvwa.lab" → diarahkan ke halaman phishing buatan
```

Perintah bettercap:
```
set dns.spoof.domains dvwa.lab,webgoat.lab
set dns.spoof.address 192.168.56.10
dns.spoof on
```

### 2C — HTTP Injection

Menyisipkan JavaScript ke dalam halaman HTTP yang diakses victim secara real-time.

```
Teknik: bettercap http.proxy + inject module
Skenario: setiap halaman yang dibuka victim menampilkan alert() atau beacon ke attacker
```

### 2D — Session Hijacking

Capture session cookie dari HTTP traffic, gunakan untuk login tanpa password.

```
Teknik: net.sniff capture Set-Cookie header, replay via curl/browser
Target: DVWA session setelah login berhasil
```

---

## 🟡 Phase 3 — Detection & Defense

Tujuan: lab tidak hanya mengajarkan menyerang, tapi juga mendeteksi dan mencegah.

### 3A — Deteksi ARP Spoofing dari sisi victim

Install dan konfigurasi ARP monitoring di Ubuntu VM:

```bash
# arpwatch — monitor perubahan ARP table
sudo apt install arpwatch
sudo arpwatch -i enp0s8

# XArp — GUI ARP spoof detector
# atau manual monitoring:
watch -n 1 arp -n
```

Dokumentasi: kapan alert muncul, berapa lama delay deteksi, false positive rate.

### 3B — Network-level Detection dengan Wireshark

Capture dan analisis pola ARP yang abnormal:
- Gratuitous ARP berulang dari satu MAC
- Dua IP berbeda mengklaim MAC yang sama
- ARP reply tanpa ARP request sebelumnya

### 3C — HTTPS sebagai mitigasi

Demonstrasi bahwa credential **tidak** ter-capture ketika target menggunakan HTTPS dengan sertifikat valid (tanpa sslstrip).

### 3D — Static ARP Entry

Konfigurasi ARP entry statis di Ubuntu untuk melindungi dari spoofing:

```bash
sudo arp -s 192.168.56.20 <mac-dvwa>
```

Verifikasi bahwa serangan ARP spoof tidak bisa mengubah entry statis.

---

## 🟠 Phase 4 — Advanced Scenarios

### 4A — Evil Twin / Rogue DHCP

Jalankan DHCP server palsu di container attacker, race condition dengan DHCP server legitimate untuk mendapatkan victim menggunakan gateway palsu.

### 4B — MITM dengan Metasploitable sebagai target aktif

Eksploitasi layanan di Metasploitable (FTP, Telnet, HTTP) via posisi MITM — capture plaintext credentials dari protokol legacy.

Target layanan Metasploitable:
- FTP (port 21) — credential plaintext
- Telnet (port 23) — full session capture
- HTTP (port 80) — DVWA Metasploitable version

### 4C — Logging & SIEM Integration

Forward semua capture bettercap ke file JSON, kirim ke stack ELK (Elasticsearch + Logstash + Kibana) untuk visualisasi serangan secara real-time.

```
bettercap → JSON log → Logstash → Elasticsearch → Kibana dashboard
```

---

## 🟣 Phase 5 — Laporan & Publikasi

### 5A — Laporan teknis lengkap

Tulis laporan dalam format penetration test report:
- Executive summary
- Scope dan metodologi
- Temuan per fase
- Risk rating (CVSS scoring)
- Rekomendasi mitigasi

### 5B — Blog post / writeup

Publikasikan writeup di Medium, Dev.to, atau personal blog — dokumentasi perjalanan dari zero ke berhasil termasuk semua kegagalan dan RCA.

### 5C — Demo video

Record screencast demonstrasi serangan end-to-end:
1. Setup lab (setup.sh)
2. ARP spoof aktif
3. Victim login DVWA
4. Credentials muncul di bettercap
5. Defense — ARP monitoring mendeteksi serangan

---

## Prioritas Rekomendasi

Urutan pengerjaan yang disarankan berdasarkan nilai pembelajaran:

1. **Phase 3A** dulu — deteksi ARP spoof di Ubuntu (paling edukatif, melengkapi Phase 1)
2. **Phase 2A** — SSL strip (ekstensi langsung dari setup yang sudah ada)
3. **Phase 2D** — session hijacking (leverage capture yang sudah berjalan)
4. **Phase 2B** — DNS spoofing (modul bettercap sudah tersedia)
5. **Phase 4B** — Metasploitable exploitation (memanfaatkan VM yang sudah ada)
