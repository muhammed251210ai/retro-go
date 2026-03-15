FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click pyserial cryptography

COPY . .

# MUHAMMED: Derleme sirasinda hata olursa tam logu gorelim diye '|| exit 1' biraktim.
RUN . /opt/esp/idf/export.sh && \
    python3 rg_tool.py --target=esp32-s3-devkit release

RUN mkdir -p /kynex_out && \
    find build -name "bootloader.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "partition-table.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "launcher.bin" -exec cp {} /kynex_out/ \; && \
    find build -name "*.bin" ! -path "*/bootloader/*" ! -path "*/partition_table/*" -exec cp {} /kynex_out/ \;
