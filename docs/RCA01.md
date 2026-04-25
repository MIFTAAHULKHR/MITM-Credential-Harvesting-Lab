# 🔍 Root Cause Analysis (RCA) — Core Challenges

Dokumen ini mencatat masalah arsitektural dan operasional utama yang dipecahkan selama pembangunan lab simulasi MITM (*Man-in-the-Middle*).

## 1. Visualisasi Solusi Jaringan (Host vs Macvlan)

Di bawah ini adalah diagram arsitektur yang menunjukkan mengapa *spoofer* yang dijalankan di *Host* gagal, dan mengapa Docker Macvlan berhasil menjadi solusi.

```mermaid
graph TD
    subgraph Kali Host
        VBOX[vboxnet0 - MAC: 0a:00:27...]
    end

    subgraph Docker Macvlan Network
        Attacker[Bettercap Container - MAC: 96:d0:47...]
        Target[DVWA Target - IP: .20]
    end

    Victim[Ubuntu VM - IP: .101]

    Victim -.->|Serangan Gagal| VBOX
    VBOX -.->|Packet Dropped by Kernel| Victim
    
    Victim ==>|Serangan Sukses| Attacker
    Attacker ==>|Forward Traffic| Target
