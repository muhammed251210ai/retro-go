# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v194.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Master derleme
# * Hata Düzeltme: SDKConfig temizliği ve CMake reconfigure zorlaması eklendi.
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Gerekli sistem kütüphaneleri
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Python bağımlılıkları (Retro-Go imaj işleme araçları için)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Proje dosyalarını Docker içine aktar
ADD . /app

# Yamaları Uygula (Eğer mevcutsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

# MUHAMMED: AGRESİF DERLEME TEMİZLİĞİ
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Eski yapılandırma dosyalarını silerek çakışmayı önlüyoruz (Exit Status 2 Fix)
    rm -rf build sdkconfig sdkconfig.old && \
    mkdir -p build && \
    # Hedefi S3 olarak mühürle
    idf.py set-target esp32s3 && \
    # Retro-Go'nun S3 Devkit hedefiyle release derlemesi
    python3 rg_tool.py --target=esp32-s3-devkit release

# Derlenen çıktıları doğrula
RUN ls -R build/
