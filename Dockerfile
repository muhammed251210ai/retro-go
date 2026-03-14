# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v195.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Launcher derleme
# * Hata Düzeltme: CMakeLists root hatası giderildi, rg_tool'a tam yetki verildi.
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

# Python kütüphaneleri (Pillow olmadan imajlar derlenmez)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Proje dosyalarını Docker içine al
ADD . /app

# Yamaları Uygula (Eğer tools/patches klasörü varsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Yama atlandi"; \
        done; \
    fi

# MUHAMMED: DERLEME OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Build klasörünü temizle
    rm -rf build && \
    mkdir -p build && \
    # DOĞRUDAN ARAÇ ÜZERİNDEN GİDİYORUZ (Kök dizinde idf.py çalıştırmıyoruz)
    # rg_tool otomatik olarak launcher klasörüne girip S3 için derlemeyi başlatır.
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları doğrula
RUN ls -R build/
