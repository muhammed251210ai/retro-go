# **************************************************************************
# * Kynex Sovereign - Log Revealer Dockerfile v283.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Derleme çökerse hatanın son 200 satırını ekrana ifşa eder!
# **************************************************************************
FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

# Git ve Bagimliliklar
RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

COPY . .

# MUHAMMED: İŞTE SİHİR BURADA! Hata olursa log.txt dosyasının son 200 satırını ekrana basıp öyle kapanacak.
RUN . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    (python3 rg_tool.py --target=esp32-s3-devkit release > build_log.txt 2>&1 || (echo -e "\n\n==========================================\n=== KYNEX DERLEME HATASI DETAYLARI ===\n==========================================" && tail -n 200 build_log.txt && exit 1))

# Çıktıları Topla (Başarılı olanları alır)
RUN mkdir -p /kynex_out && \
    cp build/bootloader/bootloader.bin /kynex_out/bootloader.bin || true && \
    cp build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp build/launcher.bin /kynex_out/launcher.bin || true && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \; || true
