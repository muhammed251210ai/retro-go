# **************************************************************************
# * Kynex Sovereign - The Harvest Dockerfile v289.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Üretilen tüm BIN dosyalarını kendi klasörlerinden nokta atışı toplar!
# **************************************************************************
FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

COPY . .

# MUHAMMED: CERRAHİ MÜDAHALE (Çakışmaları önleyen kalkanımız)
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bmPS\b/mHANDY_PS/g' {} + || true
RUN sed -i 's/#define BIT(n,r)/#undef BIT\n#define BIT(n,r)/g' retro-core/components/gnuboy/cpu.c || true
RUN sed -i 's/#define BIT(cycles,/#undef BIT\n#define BIT(cycles,/g' retro-core/components/nofrendo/nes/cpu.c || true

# Derleme Aşaması
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit release > /kynex_out/build_log.txt 2>&1 || true

# Bin Dosyalarını Klasörlerinden Nokta Atışı Topla
# MUHAMMED: İşte sorun buradaydı, artık dosyaları tam üretildikleri yerden çekiyoruz!
RUN cp launcher/build/bootloader/bootloader.bin /kynex_out/bootloader.bin || true && \
    cp launcher/build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp launcher/build/launcher.bin /kynex_out/launcher.bin || true && \
    cp retro-core/build/retro-core.bin /kynex_out/retro-core.bin || true && \
    cp prboom-go/build/prboom-go.bin /kynex_out/prboom-go.bin || true && \
    cp gwenesis/build/gwenesis.bin /kynex_out/gwenesis.bin || true && \
    cp fmsx/build/fmsx.bin /kynex_out/fmsx.bin || true && \
    cp *.img /kynex_out/ || true
