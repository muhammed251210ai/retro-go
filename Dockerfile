# **************************************************************************
# * Kynex Sovereign - Masterpiece Dockerfile v294.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Tüm BIN ve o devasa IMG dosyasını eksiksiz toplar!
# **************************************************************************
FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# MUHAMMED: CERRAHİ MÜDAHALE (Kalkanlar devrede)
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bmPS\b/mHANDY_PS/g' {} + || true
RUN sed -i 's/#define BIT(n,r)/#undef BIT\n#define BIT(n,r)/g' retro-core/components/gnuboy/cpu.c || true
RUN sed -i 's/#define BIT(cycles,/#undef BIT\n#define BIT(cycles,/g' retro-core/components/nofrendo/nes/cpu.c || true

# MUHAMMED: SIZMA OPERASYONU (16MB Haritası)
RUN cp partitions.csv components/retro-go/targets/esp32-s3-devkit/partitions.csv || true

# Derleme Aşaması
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release

# MUHAMMED: İŞTE BURASI DEĞİŞTİ! 
# IMG dosyasını nerede olursa olsun bulup kynex_out klasörüne taşıyoruz.
RUN find . -maxdepth 2 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    find . -name "bootloader.bin" -exec cp {} /kynex_out/ \; || true && \
    find . -name "partition-table.bin" -exec cp {} /kynex_out/ \; || true && \
    find . -name "launcher.bin" -exec cp {} /kynex_out/ \; || true && \
    find . -name "retro-core.bin" -exec cp {} /kynex_out/ \; || true && \
    cp build_log.txt /kynex_out/ || true
