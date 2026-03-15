# **************************************************************************
# * Kynex Sovereign - Reconnaissance Dockerfile v280.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Gizli derleme hatalarını yakalar ve build_log.txt olarak sunar.
# **************************************************************************
FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

COPY . .

# MUHAMMED: İşte sihir burada! Çökse bile 'exit 1' vermeyecek, logu dosyaya basacak.
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    (python3 rg_tool.py --target=esp32-s3-devkit release > /kynex_out/build_log.txt 2>&1 || echo "DERLEME HATASI! Log kaydedildi, CI devam ediyor...")

# Çıktıları Topla (Başarılı olanları alır, olmayanları atlar)
RUN cp build/bootloader/bootloader.bin /kynex_out/bootloader.bin || true && \
    cp build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp build/launcher.bin /kynex_out/launcher.bin || true && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \; || true
