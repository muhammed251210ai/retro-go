# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v207.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Launcher derleme
# * Hata Düzeltme: Üretilmeyen Bootloader ve Partition Table manuel tetiklendi!
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Gerekli sistem bağımlılıkları
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    ccache \
    && rm -rf /var/lib/apt/lists/*

# Proje dosyalarını Docker içine aktarıyoruz
ADD . /app

# Yamaları Uygula (Eğer mevcutsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

# MUHAMMED: EKSİK PARÇA TAMAMLAMA VE RADAR OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # Çakışan fonksiyonu derlemeden önce siliyoruz
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # Eski build verilerini kökünden kazı
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    # 1. AŞAMA: rg_tool ana derlemeyi başlatır (Sadece launcher.bin'i üretip Atari'de çökecektir)
    (python3 rg_tool.py --target=esp32-s3-devkit release || true) && \
    # 2. KRİTİK AŞAMA: rg_tool'un üretmediği o meşhur Bootloader ve Haritayı biz ZORLA ürettiriyoruz!
    cd /app/launcher && \
    idf.py -DRG_PROJECT_APP=launcher -DRG_BUILD_TARGET=RG_TARGET_ESP32_S3_DEVKIT -DRG_BUILD_RELEASE=1 bootloader partition-table && \
    # 3. RADAR AŞAMASI: Üretilen her şeyi bul ve bizim güvenli kasamıza kilitle
    mkdir -p /kynex_out && \
    find /app -name "launcher.bin" -type f -exec cp {} /kynex_out/launcher.bin \; && \
    find /app -name "bootloader.bin" -type f -exec cp {} /kynex_out/bootloader.bin \; && \
    find /app -name "partition-table.bin" -type f -exec cp {} /kynex_out/partition-table.bin \;

# Kasa içeriğini ekrana yazdır (Loglarda başarıyı görmek için)
RUN ls -la /kynex_out/
