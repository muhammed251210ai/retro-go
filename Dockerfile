# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Gerekli bağımlılıkları kur
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install pillow click

ADD . /app

# Yamaları Uygula (Panic hook ve SD Fix)
RUN cd /opt/esp/idf && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff" && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"

# MUHAMMED: DERLEME VE TEK DOSYA BİRLEŞTİRME OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # 1. Klasörleri hazırla
    mkdir -p build && \
    # 2. Retro-Go Launcher'ı derle (S3 için)
    python rg_tool.py --target=esp32-s3-devkit release && \
    # 3. TÜM PARÇALARI TEK BİR DOSYADA DİKİYORUZ
    # Not: ffat.bin dosyasının projenin ana dizininde olduğu varsayılır.
    esptool.py --chip esp32s3 merge_bin \
    -o build/MASTER_RETRO_GO.bin \
    --flash_mode dio \
    --flash_size 16MB \
    0x0000 build/bootloader/bootloader.bin \
    0x8000 build/partition_table/partition-table.bin \
    0x10000 build/launcher.bin \
    0x410000 ffat.bin

# Sonuçları listele
RUN ls -l build/MASTER_RETRO_GO.bin
