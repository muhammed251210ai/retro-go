# **************************************************************************
# * Kynex Sovereign - Brute Force Builder Dockerfile v275.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Tüm bin dosyalarını (Boot, Partition, Launcher, Cores) üretir.
# **************************************************************************

FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

# Sistem Paketleri ve Kesin Bagimliliklar
# MUHAMMED: Eksik olabilecek tüm kütüphaneleri buraya ekledim.
RUN apt-get update && apt-get install -y python3-pip git curl libusb-1.0-0 && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography 

# Git Güvenlik Mührü (Docker içinde Git hatalarını bitirir)
RUN git config --global --add safe.directory '*'

COPY . .

# MUHAMMED: Derleme adımı. 
# rg_tool.py hata verse bile logları görebilmemiz için bash script içine aldık.
RUN . /opt/esp/idf/export.sh && \
    echo "Derleme basliyor..." && \
    python3 rg_tool.py --target=esp32-s3-devkit release || (echo "Hata olustu! Loglar inceleniyor..." && exit 1)

# Çıktıları kynex_out klasörüne taşı
RUN mkdir -p /kynex_out && \
    cp build/bootloader/bootloader.bin /kynex_out/bootloader.bin || true && \
    cp build/partition_table/partition-table.bin /kynex_out/partition-table.bin || true && \
    cp build/launcher.bin /kynex_out/launcher.bin || true && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \; || true
