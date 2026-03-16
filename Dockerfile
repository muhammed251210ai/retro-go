# **************************************************************************
# * Kynex Sovereign - The Hijacker Dockerfile v306.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: Otomatik silinen partition tablosunu ESP-IDF aracıyla zorla üretir!
# **************************************************************************
FROM espressif/idf:release-v4.4
WORKDIR /app
SHELL ["/bin/bash", "-c"]

RUN git config --global --add safe.directory '*' && \
    apt-get update && apt-get install -y python3-pip git curl && \
    python3 -m pip install --upgrade pip pillow click pyserial cryptography

COPY . .

# MUHAMMED: EMÜLATÖR CERRAHİSİ
RUN find retro-core/components/snes9x -type f -exec sed -i 's/\bBIT8\b/SNES_BIT8/g; s/\bBIT16\b/SNES_BIT16/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bINTSET\b/HANDY_INTSET/g' {} + || true
RUN find retro-core/components/handy -type f -exec sed -i 's/\bPS\b/HANDY_PS/g' {} + || true

# MUHAMMED: KENDİ HARİTAMIZI YAZIYORUZ! (Logdaki adreslere göre milimetrik hesaplandı)
# 0x460000 adresinden itibaren geriye kalan tüm 11.6 MB alanı "storage" yapıyoruz.
RUN echo -e "nvs,data,nvs,0x9000,0x4000,\notadata,data,ota,0xd000,0x2000,\nphy_init,data,phy,0xf000,0x1000,\nlauncher,app,ota_0,0x10000,0x100000,\nretro-core,app,ota_1,0x110000,0x100000,\nprboom-go,app,ota_2,0x210000,0x0c0000,\ngwenesis,app,ota_3,0x2d0000,0x100000,\nfmsx,app,ota_4,0x3d0000,0x090000,\nstorage,data,fat,0x460000,0xBA0000," > kynex_map.csv

# Derleme Aşaması ve Haritayı Derleme
RUN mkdir -p /kynex_out && \
    . /opt/esp/idf/export.sh && \
    rm -rf build sdkconfig sdkconfig.old && \
    python3 rg_tool.py --target=esp32-s3-devkit release && \
    python3 $IDF_PATH/components/partition_table/gen_esp32part.py kynex_map.csv /kynex_out/kynex_partition_table.bin

# Diğer Çıktıları Topla
RUN find . -maxdepth 3 -name "*.img" -exec cp {} /kynex_out/kynex_full_system.img \; || true && \
    find . -name "*.bin" -exec cp {} /kynex_out/ \; || true
