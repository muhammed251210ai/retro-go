FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# EMÜLATÖR CERRAHİSİ (Aynen devam)
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true

# MUHAMMED: ZORLAYICI AYARLAR! 
# Derleyicinin bizim CSV'mizi kullanması için sdkconfig'i manipüle ediyoruz.
RUN mkdir -p components/retro-go/targets/esp32-s3-devkit/ && \
    cp partitions.csv components/retro-go/targets/esp32-s3-devkit/partitions.csv && \
    cp partitions.csv launcher/partitions.csv && \
    cp partitions.csv retro-core/partitions.csv

# Derleme ve sdkconfig zorlaması
RUN . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit config && \
    sed -i 's/CONFIG_PARTITION_TABLE_CUSTOM=n/CONFIG_PARTITION_TABLE_CUSTOM=y/g' sdkconfig && \
    sed -i 's/CONFIG_PARTITION_TABLE_FILENAME=.*/CONFIG_PARTITION_TABLE_FILENAME="partitions.csv"/g' sdkconfig && \
    python3 rg_tool.py --target=esp32-s3-devkit release

RUN mkdir -p /kynex_out && \
    find . -maxdepth 3 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    find . -name "*.bin" -exec cp {} /kynex_out/ \; || true
