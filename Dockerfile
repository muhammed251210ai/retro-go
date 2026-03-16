FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# MUHAMMED: EMÜLATÖR CERRAHİSİ
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true

# MUHAMMED: 16MB VE SD HARİTASI ENJEKSİYONU
# Sistemin orijinal hedef ayarlarını 16MB'a zorluyoruz.
RUN echo "CONFIG_PARTITION_TABLE_CUSTOM=y" >> components/retro-go/targets/esp32-s3-devkit/sdkconfig && \
    echo "CONFIG_PARTITION_TABLE_FILENAME=\"partitions.csv\"" >> components/retro-go/targets/esp32-s3-devkit/sdkconfig && \
    cp partitions.csv components/retro-go/targets/esp32-s3-devkit/partitions.csv && \
    cp partitions.csv launcher/partitions.csv && \
    cp partitions.csv retro-core/partitions.csv

# Derleme Aşaması
RUN . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları Topla
RUN mkdir -p /kynex_out && \
    find . -maxdepth 3 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    find . -name "*.bin" -exec cp {} /kynex_out/ \; || true
