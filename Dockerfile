# **************************************************************************
# * Kynex Sovereign - Nuclear Bypass Dockerfile v222.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Recovery Mode kodunu launcher çekirdeğinden tamamen söküp atar.
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

# MUHAMMED: NÜKLEER RECOVERY BYPASS OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # 1. Çakışan fonksiyonu derlemeden önce siliyoruz
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # 2. KRİTİK BYPASS: Recovery moduna girişi sağlayan TÜM mantığı iptal ediyoruz.
    # Bu komut 'RG_STATUS_RECOVERY' durumunu gördüğü her yerde 0 (Normal) yapar.
    find /app -name "*.c" -exec sed -i 's/RG_STATUS_RECOVERY/0/g' {} + && \
    find /app -name "*.h" -exec sed -i 's/RG_STATUS_RECOVERY/0/g' {} + && \
    # 3. Ekranın dikey kalmasını engellemek için ana ayarları zorluyoruz
    sed -i 's/RG_SCREEN_ROTATE_AUTO/RG_SCREEN_ROTATE_90/g' /app/components/retro-go/rg_display.c || true && \
    # 4. Hafıza mount edilemezse SORMADAN format at!
    sed -i 's/.format_if_mount_failed = false/.format_if_mount_failed = true/g' /app/components/retro-go/rg_storage.c && \
    # 5. WiFi yolunu /sd'den /ffat'a zorla
    sed -i 's/\/sd/\/ffat/g' /app/components/retro-go/rg_storage.c || true && \
    # Eski build verilerini temizle
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    # 6. AŞAMA: Ana derleme
    (python3 rg_tool.py --target=esp32-s3-devkit release || true) && \
    # 7. AŞAMA: Bootloader ve Partition Table'ı zorla üretiyoruz
    cd /app/launcher && \
    idf.py -DRG_PROJECT_APP=launcher -DRG_BUILD_TARGET=RG_TARGET_ESP32_S3_DEVKIT -DRG_BUILD_RELEASE=1 bootloader partition-table && \
    # 8. AŞAMA: Radar ile topla ve kasaya kilitle
    mkdir -p /kynex_out && \
    find /app -name "launcher.bin" -type f -exec cp {} /kynex_out/launcher.bin \; && \
    find /app -name "bootloader.bin" -type f -exec cp {} /kynex_out/bootloader.bin \; && \
    find /app -name "partition-table.bin" -type f -exec cp {} /kynex_out/partition-table.bin \;

# Doğrulama
RUN ls -la /kynex_out/
