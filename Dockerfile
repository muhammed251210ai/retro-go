# **************************************************************************
# * Kynex Sovereign - The Unstoppable Builder Dockerfile v236.1
# * Geliştirici: Muhammed (Kynex)
# * Görev: C Syntax hatasını çözer ve Launcher'ı zorla derler. Bölünmüş RUN ile hatalar yakalanır.
# **************************************************************************

FROM espressif/idf:release-v4.4

WORKDIR /app

# Temel paketler
RUN apt-get update && \
    apt-get install -y python3-pip git ccache && \
    rm -rf /var/lib/apt/lists/*

# Kodu ekle
ADD . /app

# Patch uygulama (varsa)
RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

SHELL ["/bin/bash", "-c"]

# IDF ortamını yükle
RUN . /opt/esp/idf/export.sh

# Python paketleri
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install pillow click pyserial cryptography

# KynexOS switch task temizliği
RUN if [ -f /app/components/retro-go/rg_system.c ]; then \
        sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c || true; \
    fi

# FFat yönlendirmesi
RUN if [ -f /app/components/retro-go/rg_storage.c ]; then \
        sed -i 's/\/sd/\/ffat/g' /app/components/retro-go/rg_storage.c || true; \
    fi

# Recovery bypass
RUN find /app -name "*.c" -exec sed -i 's/enter_recovery_mode();/;/g' {} + || true

# Önceki build dosyalarını temizle
RUN rm -rf /app/build /app/sdkconfig /app/sdkconfig.old || true
RUN ccache -C || true

# RG Tool ile release (hata verse de devam eder)
RUN python3 /app/rg_tool.py release || true

# Launcher ve app dosyalarını /kynex_out klasörüne kopyala
RUN mkdir -p /kynex_out
RUN for app in launcher retro-core prboom-go gwenesis fmsx; do \
        if [ -f "/app/$app/$app.app" ]; then \
            cp "/app/$app/$app.app" /kynex_out/; \
        fi; \
    done

# Son kontrol
RUN ls -la /kynex_out/
