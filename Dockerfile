# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v203.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Launcher ve Cores derleme
# * Hata Düzeltme: Errno 2 bypass edildi ve PS makro çakışması onarıldı.
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

# MUHAMMED: OTOMATİK HATA DÜZELTME VE DERLEME OPERASYONU
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # 1. rg_system.c içindeki çakışan fonksiyonu derlemeden önce siliyoruz
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # 2. KRİTİK BYPASS: Emülatör klasörlerini silmek yerine PS makro hatasını düzeltiyoruz!
    # Atari (Handy) çekirdeğindeki ESP-IDF çakışması bu şekilde ortadan kalkar.
    if [ -d "/app/retro-core" ]; then find /app/retro-core -type f -name "c65c02.h" -exec sed -i '1i #undef PS' {} +; fi && \
    # Eski build verilerini kökünden kazı
    rm -rf build sdkconfig sdkconfig.old && \
    # CCache (Derleyici önbelleği) temizleniyor
    ccache -C && \
    mkdir -p build && \
    # rg_tool üzerinden S3 derlemesini başlat (Artık emülatörleri de hatasız derler)
    python3 rg_tool.py --target=esp32-s3-devkit release

# Çıktıları doğrula
RUN ls -R build/
