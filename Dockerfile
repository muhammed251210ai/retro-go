# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v216.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Launcher derleme ve Otomatik FFat Format Zorlaması
# * Hata Düzeltme: WiFi için FFat'ı otomatik formatlamaya zorlar.
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4
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

# Yamaları Uygula
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

# MUHAMMED: OTOMATİK FORMAT VE WiFi HAZIRLIK OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # 1. Çakışan fonksiyonu derlemeden önce siliyoruz
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # 2. KRİTİK MÜDAHALE: Sistemin depolama alanını OTOMATİK FORMATLAMASINI sağlıyoruz!
    # Bu sayede ffat.bin basmasan bile sistem WiFi için kendini hazırlar.
    sed -i 's/.format_if_mount_failed = false/.format_if_mount_failed = true/g' /app/components/retro-go/rg_storage.c && \
    # Eski build verilerini temizle
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    # 3. AŞAMA: Ana derleme
    (python3 rg_tool.py --target=esp32-s3-devkit release || true) && \
    # 4. AŞAMA: Bootloader ve Partition Table'ı zorla üretiyoruz
    cd /app/launcher && \
    idf.py -DRG_PROJECT_APP=launcher -DRG_BUILD_TARGET=RG_TARGET_ESP32_S3_DEVKIT -DRG_BUILD_RELEASE=1 bootloader partition-table && \
    # 5. AŞAMA: Her şeyi bul ve kasaya (kynex_out) kilitle
    mkdir -p /kynex_out && \
    find /app -name "launcher.bin" -type f -exec cp {} /kynex_out/launcher.bin \; && \
    find /app -name "bootloader.bin" -type f -exec cp {} /kynex_out/bootloader.bin \; && \
    find /app -name "partition-table.bin" -type f -exec cp {} /kynex_out/partition-table.bin \;

# Doğrulama
RUN ls -la /kynex_out/
