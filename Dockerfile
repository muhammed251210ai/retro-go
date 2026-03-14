# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Bağımlılıkları tek seferde kurarak önbellekten kazanç sağlıyoruz
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install pillow click

ADD . /app

# Yamaları Uygula
RUN cd /opt/esp/idf && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff" && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"

# MUHAMMED: Hata ve Hız Ayarı
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Build klasörünü garantiye al
    mkdir -p build && \
    # Sadece senin S3 konsolun için derleme yapıyoruz
    python rg_tool.py --target=esp32-s3-devkit release && \
    # MUHAMMED: TÜM DOSYALARI TEK BİR MASTER IMAGE OLARAK BİRLEŞTİRİYORUZ
    # Not: ffat.bin ve firmware.bin dosyalarının ana dizinde olduğu varsayılır.
    esptool.py --chip esp32s3 merge_bin \
    -o build/MASTER_KYNEX_SOVEREIGN.bin \
    --flash_mode dio \
    --flash_size 16MB \
    0x0000 build/bootloader/bootloader.bin \
    0x8000 build/partition_table/partition-table.bin \
    0x10000 build/launcher.bin \
    0x410000 firmware.bin \
    0xC10000 ffat.bin

# Hata Veren Satır Fixlendi: Artık alt klasörleri de kapsıyor
RUN ls -R build/
