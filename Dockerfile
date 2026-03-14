# **************************************************************************
# * Kynex Sovereign - Retro-Go Master Dockerfile v208.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Launcher derleme ve Bootloader/Partition üretimi
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
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
    rm -rf build sdkconfig sdkconfig.old && \
    ccache -C && \
    (python3 rg_tool.py --target=esp32-s3-devkit release || true) && \
    cd /app/launcher && \
    idf.py -DRG_PROJECT_APP=launcher -DRG_BUILD_TARGET=RG_TARGET_ESP32_S3_DEVKIT -DRG_BUILD_RELEASE=1 bootloader partition-table && \
    mkdir -p /kynex_out && \
    find /app -name "launcher.bin" -type f -exec cp {} /kynex_out/launcher.bin \; && \
    find /app -name "bootloader.bin" -type f -exec cp {} /kynex_out/bootloader.bin \; && \
    find /app -name "partition-table.bin" -type f -exec cp {} /kynex_out/partition-table.bin \;

RUN ls -la /kynex_out/
