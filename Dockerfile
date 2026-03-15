FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# Emülatör cerrahisi
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true

# Derleme
RUN . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit --partition-table=partitions.csv release

# MUHAMMED: DOSYA TOPLAMA SİHRİ!
# Kynex_out klasörüne her şeyi kaba kuvvetle kopyalıyoruz.
RUN mkdir -p /kynex_out && \
    find . -name "*.bin" -exec cp {} /kynex_out/ \; && \
    find . -name "*.img" -exec cp {} /kynex_out/ \; && \
    cp build_log.txt /kynex_out/ || true
