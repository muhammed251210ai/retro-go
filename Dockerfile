# **************************************************************************
# * Kynex Sovereign - Bulletproof Factory Dockerfile v271.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Git engellerini aşar, Launcher ve tüm Çekirdekleri modüler üretir.
# **************************************************************************

FROM espressif/idf:release-v4.4

# Çalışma dizini
WORKDIR /app

# Git güvenlik ayarı ve bağımlılıklar
# MUHAMMED: Docker içindeki Git'in 'unsafe directory' hatası vermesini engelliyoruz.
RUN git config --global --add safe.directory /app && \
    apt-get update && apt-get install -y python3-pip git && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Projeyi kopyala
COPY . .

# Derleme ve Çıktı Toplama
# MUHAMMED: Derleme komutunu 'release' modunda çalıştırıp çıktıları kynex_out'a topluyoruz.
RUN . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit release || true && \
    mkdir -p /kynex_out && \
    find build -name "bootloader.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "partition-table.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "launcher.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "*.bin" ! -name "bootloader.bin" ! -name "partition-table.bin" ! -name "launcher.bin" -exec cp {} /kynex_out/ \;
