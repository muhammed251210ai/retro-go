FROM espressif/idf:release-v4.4

WORKDIR /app
SHELL ["/bin/bash", "-c"]

# Sistem ve Bagimliliklar
RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

COPY . .

# MUHAMMED: Eski build kalintilarini siliyoruz ki tertemiz baslasin.
RUN . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release

# Ciktilari Topla
RUN mkdir -p /kynex_out && \
    cp build/bootloader/bootloader.bin /kynex_out/bootloader.bin && \
    cp build/partition_table/partition-table.bin /kynex_out/partition-table.bin && \
    cp build/launcher.bin /kynex_out/launcher.bin && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \;
