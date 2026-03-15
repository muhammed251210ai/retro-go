# **************************************************************************
# * Kynex Sovereign - Precision Strike Dockerfile v288.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Doğru klasör yolları (retro-core/*) ile kesin cerrahi müdahale!
# **************************************************************************
FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

COPY . .

# MUHAMMED: İŞTE KOORDİNATLARI DÜZELTTİK! 
# Emülatörler 'retro-core' klasörünün içindeymiş. Her komutu ayrı satıra aldık ki biri takılsa bile diğeri çalışsın.
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bmPS\b/mHANDY_PS/g' {} + || true
RUN sed -i 's/#define BIT(n,r)/#undef BIT\n#define BIT(n,r)/g' retro-core/components/gnuboy/cpu.c || true
RUN sed -i 's/#define BIT(cycles,/#undef BIT\n#define BIT(cycles,/g' retro-core/components/nofrendo/nes/cpu.c || true

# Derleme Aşaması (Truva Atı log koruması hala devrede)
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    (python3 rg_tool.py --target=esp32-s3-devkit release > /kynex_out/build_log.txt 2>&1 || true)

# Bin Dosyalarını Topla
RUN cp build/bootloader/bootloader.bin /kynex_out/bootloader.bin || true && \
    cp build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp build/launcher.bin /kynex_out/launcher.bin || true && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \; || true
