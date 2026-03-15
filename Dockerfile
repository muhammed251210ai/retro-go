# **************************************************************************
# * Kynex Sovereign - Deep Clean Builder Dockerfile v274.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Tüm bin dosyalarını (Boot, Partition, Launcher, Cores) hatasız üretir.
# **************************************************************************

FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

# Sistem Paketleri ve Git Güvenlik Mührü
RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl libusb-1.0-0 && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography 

# Projeyi kopyala
COPY . .

# MUHAMMED: Derleme öncesi temizlik ve kesin hedef belirleme
# rg_tool.py bazen eski konfigürasyonlar yüzünden çökebilir, temizleyip başlıyoruz.
RUN . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig && \
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları Klasöre Topla
RUN mkdir -p /kynex_out && \
    cp build/bootloader/bootloader.bin /kynex_out/bootloader.bin && \
    cp build/partition_table/partition-table.bin /kynex_out/partition-table.bin && \
    cp build/launcher.bin /kynex_out/launcher.bin && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \;
