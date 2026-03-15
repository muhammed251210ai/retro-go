# **************************************************************************
# * Kynex Sovereign - The Unstoppable Builder Dockerfile v236.1
# * Geliştirici: Muhammed (Kynex)
# * Görev: C Syntax hatasını çözer, Launcher ve tüm app’leri .app olarak derler.
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
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography && \
    # KynexOs çakışma temizliği
    sed -i '/static void kynex_os_switch_task/,/^}/d' /app/components/retro-go/rg_system.c && \
    # FFat Yönlendirmesi
    sed -i 's/\/sd/\/ffat/g' /app/components/retro-go/rg_storage.c || true && \
    # C bypass taktiği
    find /app -name "*.c" -exec sed -i 's/enter_recovery_mode();/;/g' {} + && \
    # Temizlik
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    # Tüm app’leri release modda build et (.app üretimi)
    python3 rg_tool.py release && \
    mkdir -p /kynex_out && \
    # Launcher ve diğer tüm app’lerin .app dosyalarını kopyala
    for app in launcher retro-core prboom-go gwenesis fmsx; do \
        if [ -f "/app/$app/$app.app" ]; then \
            cp "/app/$app/$app.app" /kynex_out/; \
        fi; \
    done && \
    ls -la /kynex_out/
