# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v193.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Master derleme
# * Hata Düzeltme: Git kütüphanesi ve Python bağımlılıkları eklendi.
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# MUHAMMED: Gerekli tüm sistem bağımlılıklarını kuruyoruz
# git, rg_tool.py'nin versiyon çekmesi için şarttır!
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# MUHAMMED: Python bağımlılıklarını garantiye alıyoruz
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

# Proje dosyalarını Docker içine alıyoruz (.git klasörü dahil)
ADD . /app

# Yamaları Uygula (Eğer yama dosyaları tools/patches altında varsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Yama atlandi: $f"; \
        done; \
    fi

# MUHAMMED: Derleme Hazırlığı
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Her ihtimale karşı temiz bir build klasörü
    rm -rf build && \
    mkdir -p build && \
    # Retro-Go'nun S3 Devkit hedefiyle release derlemesi
    python3 rg_tool.py --target=esp32-s3-devkit release

# Derlenen çıktıları listele (Hata ayıklama için)
RUN ls -R build/
