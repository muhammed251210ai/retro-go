# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v202.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde SADECE S3 Launcher derleme
# * Hata Düzeltme: Çekirdek (Core) hatalarını bypass etmek için izole derleme.
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Gerekli sistem bağımlılıkları
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

# MUHAMMED: İZOLE LAUNCHER DERLEME OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # rg_system.c içindeki çakışan fonksiyonu derlemeden önce siliyoruz
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # KRİTİK BYPASS: Kullanmayacağımız ve hata veren emülatör klasörlerini SİLİYORUZ!
    # Bu sayede rg_tool sadece launcher'ı derler, zaman kazanırız ve hata almayız.
    rm -rf /app/retro-core /app/prboom-go /app/gwenesis /app/fmsx && \
    # Eski build verilerini kökünden kazı
    rm -rf build sdkconfig sdkconfig.old && \
    # CCache (Derleyici önbelleği) temizleniyor
    ccache -C && \
    mkdir -p build && \
    # rg_tool üzerinden sadece elde kalan (Launcher) S3 için derlenir
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları doğrula
RUN ls -R build/
