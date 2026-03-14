# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v197.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Launcher derleme
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Gerekli sistem bağımlılıkları
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Python kütüphaneleri (Retro-Go araçları için şart)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Proje dosyalarını Docker içine aktarıyoruz
ADD . /app

# Yamaları Uygula (Eğer mevcutsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

# MUHAMMED: DERLEME OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Eski build verilerini temizle
    rm -rf build && \
    mkdir -p build && \
    # rg_tool üzerinden S3 derlemesini başlat
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları doğrula
RUN ls -R build/
