# **************************************************************************
# * Kynex Sovereign - Recovery Assassin Dockerfile v234.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: enter_recovery_mode çağrılarını kaynak koddan tamamen siler.
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

# MUHAMMED: KESİN VE NİHAİ RECOVERY İPTAL OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # 1. Çakışan KynexOs fonksiyonunu temizle
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # 2. WiFi ve Hafıza yolunu FFat olarak mühürle
    sed -i 's/\/sd/\/ffat/g' /app/components/retro-go/rg_storage.c || true && \
    # 3. İŞTE KİLİDİ KIRAN KOD: Recovery modunu kaynak koddan söküp atıyoruz!
    # Sistem kurtarma moduna girmeye çalışsa bile sadece "Bypassed" yazıp normal açılacak.
    find /app -name "*.c" -exec sed -i 's/enter_recovery_mode();/ESP_LOGW("KYNEX", "Recovery Bypassed!");/g' {} + && \
    # Eski build verilerini temizle
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    # 4. Ana derleme
    (python3 rg_tool.py --target=esp32-s3-devkit release || true) && \
    # 5. Bootloader ve Partition Table
    cd /app/launcher && \
    idf.py -DRG_PROJECT_APP=launcher -DRG_BUILD_TARGET=RG_TARGET_ESP32_S3_DEVKIT -DRG_BUILD_RELEASE=1 bootloader partition-table && \
    # 6. Çıktıları kasaya kilitle
    mkdir -p /kynex_out && \
    find /app -name "launcher.bin" -type f -exec cp {} /kynex_out/launcher.bin \; && \
    find /app -name "bootloader.bin" -type f -exec cp {} /kynex_out/bootloader.bin \; && \
    find /app -name "partition-table.bin" -type f -exec cp {} /kynex_out/partition-table.bin \;

# Doğrulama
RUN ls -la /kynex_out/
