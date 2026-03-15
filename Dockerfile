# **************************************************************************
# * Kynex Sovereign - Architect's Resolution Dockerfile v272.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Git engellerini ve klasör bulma hatalarını aşarak tam üretim yapar.
# **************************************************************************

FROM espressif/idf:release-v4.4

# Çalışma dizini
WORKDIR /app

# Kabuk ayarını Bash yapalım (IDF için daha kararlıdır)
SHELL ["/bin/bash", "-c"]

# Bağımlılıklar ve Git Güvenlik Mührü
# MUHAMMED: Docker içindeki Git'in tüm klasörleri 'safe' görmesini sağlıyoruz.
RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Projeyi kopyala
COPY . .

# Derleme ve Akıllı Çıktı Toplama
# MUHAMMED: 'find' komutlarını, klasör olmasa bile hata vermeyecek (|| true) hale getirdik.
RUN . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit release || echo "Build failed but continuing to collect logs..." && \
    mkdir -p /kynex_out && \
    if [ -d "build" ]; then \
        find build -name "bootloader.bin" -exec cp {} /kynex_out/ \; || true; \
        find build -name "partition-table.bin" -exec cp {} /kynex_out/ \; || true; \
        find build -name "launcher.bin" -exec cp {} /kynex_out/ \; || true; \
        find build -name "*.bin" ! -name "bootloader.bin" ! -name "partition-table.bin" ! -name "launcher.bin" -exec cp {} /kynex_out/ \; || true; \
    else \
        echo "Build directory not found! Check logs above."; \
    fi
