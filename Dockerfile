FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# EMÜLATÖR KALKANLARI
RUN find retro-core/components/snes9x -type f -exec sed -i '1i#undef BIT8\n#undef BIT16' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i '1i#undef PS\n#undef INTSET' {} + || true

# MUHAMMED: İŞTE DARBE BURADA!
# Retro-Go'nun orijinal partitions.csv dosyasını bizimkiyle değiştiriyoruz.
RUN cp partitions.csv components/retro-go/targets/esp32-s3-devkit/partitions.csv && \
    cp partitions.csv launcher/partitions.csv && \
    cp partitions.csv retro-core/partitions.csv

# Derleme
RUN . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları Topla
RUN mkdir -p /kynex_out && \
    find . -maxdepth 3 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    find . -name "*.bin" -exec cp {} /kynex_out/ \; || true
