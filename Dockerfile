FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# MUHAMMED: EMÜLATÖR CERRAHİSİ (Sadece emülatör dosyalarında isim değiştiriyoruz)
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true
RUN sed -i 's/#define BIT(n,r)/#undef BIT\n#define BIT(n,r)/g' retro-core/components/gnuboy/cpu.c || true
RUN sed -i 's/#define BIT(cycles,/#undef BIT\n#define BIT(cycles,/g' retro-core/components/nofrendo/nes/cpu.c || true

# MUHAMMED: 16MB Hafıza Kartı Desteği
RUN mkdir -p components/retro-go/targets/esp32-s3-devkit/ && \
    cp partitions.csv components/retro-go/targets/esp32-s3-devkit/partitions.csv || true

# Derleme Aşaması (Logları build_log.txt dosyasına mühürlüyoruz)
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release > /kynex_out/build_log.txt 2>&1 || (echo "Hata! Son 100 satır:" && tail -n 100 /kynex_out/build_log.txt && exit 1)

# BIN ve o meşhur IMG Dosyasını Topla
RUN find . -maxdepth 3 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    find . -name "*.bin" -exec cp {} /kynex_out/ \; || true
