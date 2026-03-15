FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# MUHAMMED: Emülatör cerrahisi
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true

# MUHAMMED: Derleme komutuna partition table'ı zorla ekletiyoruz!
RUN . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit --partition-table=partitions.csv release > build_log.txt 2>&1 || true

RUN mkdir -p /kynex_out && \
    cp launcher/build/launcher.bin /kynex_out/launcher.bin || true && \
    cp launcher/build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp *.img /kynex_out/ || true
