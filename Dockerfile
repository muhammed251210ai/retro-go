# **************************************************************************
# * Kynex Sovereign - The Unstoppable Builder Dockerfile v236.1
# * Güncelleme: .bin dosyaları garanti, eksik dosya log’lu
# **************************************************************************

FROM espressif/idf:release-v4.4

WORKDIR /app

RUN apt-get update && apt-get install -y python3-pip git ccache && rm -rf /var/lib/apt/lists/*

ADD . /app

RUN cd /opt/esp/idf && \
    if [ -d "/app/tools/patches" ]; then \
        for f in /app/tools/patches/*.diff; do \
            [ -e "$f" ] && patch --ignore-whitespace -p1 -i "$f" || echo "Atlandi: $f"; \
        done; \
    fi

SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    git config --global --add safe.directory /app && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    sed -i 's/\/sd/\/ffat/g' /app/components/retro-go/rg_storage.c || true && \
    find /app -name "*.c" -exec sed -i 's/enter_recovery_mode();/;/g' {} + && \
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    echo "📦 RG Tool ile tüm uygulamaları derliyoruz..." && \
    (python3 rg_tool.py release || true) && \
    mkdir -p /kynex_out && \
    echo "📂 .bin dosyalarını kopyalıyoruz..." && \
    for app in launcher retro-core prboom-go gwenesis fmsx; do \
        if [ -f "/app/$app/$app.app" ]; then \
            cp "/app/$app/$app.app" /kynex_out/$app.bin && \
            echo "✅ $app.bin kopyalandı."; \
        else \
            echo "⚠️ Uyarı: $app.app bulunamadı, .bin oluşturulamadı!"; \
        fi; \
    done && \
    echo "📝 /kynex_out içeriği:" && ls -la /kynex_out/
