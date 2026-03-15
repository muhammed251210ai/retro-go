# **************************************************************************
# * Kynex Sovereign - Full Modular Build Dockerfile v270.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Bootloader, Launcher ve Tüm Çekirdekleri derler.
# **************************************************************************

FROM espressif/idf:release-v4.4

# Çalışma dizini
WORKDIR /app

# Gerekli Python kütüphanelerini kur
RUN apt-get update && apt-get install -y python3-pip && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Projeyi kopyala (CI tarafından kopyalanacak)
COPY . .

# Derleme Komutu
# 'release' komutu Launcher + Cores (NES, SNES, GBA, Doom vb.) hepsini derler.
RUN . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları toplamak için bir klasör oluştur ve her şeyi oraya yığ
RUN mkdir -p /kynex_out && \
    find build -name "bootloader.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "partition-table.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "launcher.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "*.bin" ! -name "bootloader.bin" ! -name "partition-table.bin" ! -name "launcher.bin" -exec cp {} /kynex_out/ \;
