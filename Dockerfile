# **************************************************************************
# * Kynex Sovereign - Unstoppable Dockerfile v295.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: 16MB haritasını sızdırır, çakışmaları çözer ve IMG dosyasını toplar!
# **************************************************************************
FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# MUHAMMED: CERRAHİ MÜDAHALE (Emulator Çakışma Kalkanları)
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bmPS\b/mHANDY_PS/g' {} + || true
RUN sed -i 's/#define BIT(n,r)/#undef BIT\n#define BIT(n,r)/g' retro-core/components/gnuboy/cpu.c || true
RUN sed -i 's/#define BIT(cycles,/#undef BIT\n#define BIT(cycles,/g' retro-core/components/nofrendo/nes/cpu.c || true

# MUHAMMED: PARTITION TABLE SIZDIRMA (16MB Desteği)
# Dosyayı sistemin orijinal klasörüne kopyalıyoruz
RUN mkdir -p components/retro-go/targets/esp32-s3-devkit/ && \
    cp partitions.csv components/retro-go/targets/esp32-s3-devkit/partitions.csv || true

# Derleme Aşaması (Hata olursa logu ekrana basması için kurgulandı)
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release || (echo "Hata olustu! Son loglar:" && tail -n 50 build_log.txt && exit 1)

# BIN ve o meşhur IMG Dosyasını Topla
# MUHAMMED: find komutuyla her yeri tarayıp kynex_out içine mühürlüyoruz
RUN find . -maxdepth 2 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    cp launcher/build/launcher.bin /kynex_out/launcher.bin || true && \
    cp launcher/build/bootloader/bootloader.bin /kynex_out/bootloader.bin || true && \
    cp launcher/build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp retro-core/build/retro-core.bin /kynex_out/retro-core.bin || true && \
    cp build_log.txt /kynex_out/ || true
