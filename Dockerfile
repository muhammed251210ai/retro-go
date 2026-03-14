# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v200.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Launcher derleme
# * Hata Düzeltme: CCache temizliği ve mutlak sıfır noktası derlemesi.
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Gerekli sistem bağımlılıkları (Git ve diğer araçlar)
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    ccache \
    && rm -rf /var/lib/apt/lists/*

# Proje dosyalarını Docker içine aktarıyoruz
ADD . /app

# Yamaları Uygula (Eğer mevcutsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

# MUHAMMED: MUTLAK TEMİZLİK VE DERLEME OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # Eski build verilerini kökünden kazı
    rm -rf build sdkconfig sdkconfig.old && \
    # CCache (Derleyici önbelleği) tamamen temizleniyor! (Kritik Donanım Hatası Çözümü)
    ccache -C && \
    mkdir -p build && \
    # rg_tool üzerinden S3 derlemesini başlat
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları doğrula
RUN ls -R build/
